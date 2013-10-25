#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

($LOAD_PATH << File.expand_path("../lib", __FILE__)).uniq!
require 'rubygems' unless defined? Gem # rubygems is only needed in 1.8

require "./bundle/bundler/setup"
require "alfred"

require 'set'

load 'menu_items.rb'


class String
  def escape_applescript
    gsub(/(?=["\\])/, '\\')
  end
end


class Keylue < ::Alfred::Handler::Base

  def initialize(alfred, opts = {})
    super
    @settings = {
      :handler  => 'Keylue' ,
      :restart? => false
    }.update(opts)

    @local_feedbacks = []
  end


  def on_parser
    options.type = :menu
    options.keyword = 'kc'

    parser.on("-a", "--all", "all menu items") do
      options.type = :menu
    end

    parser.on("-m", "--menu", "application menu items") do
      options.type = :menu
    end

    parser.on("-s", "--services", "services menu items") do
      options.type = :services
    end

    parser.on("-k", "--keyboardmaestro", "Keyboard Maestro hotkeys") do
      options.type = :keyboardmaestro
    end

    parser.on("--keyword KEYWORD", String,
        "change default keyword kc to KEYWORD") do |v|
      options.keyword = v
    end

  end


  def on_help
    [
      {
        :kind         => 'text'                   ,
        :title        => '-m, --menu [query]'   ,
        :subtitle     => 'Show application menu items' ,
        :autocomplete => "-m #{query}"
      },
      {
        :kind         => 'text'               ,
        :title        => '-s, --services [query]'   ,
        :subtitle     => 'Show services menu items' ,
        :autocomplete => "-i #{query}"
      },
      {
        :kind         => 'text'               ,
        :title        => '-k, --keyboardmaestro [query]'   ,
        :subtitle     => 'Show Keyboard Maestro Hotkeys' ,
        :autocomplete => "-k #{query}"
      },
      {
        :kind         => 'text'                ,
        :title        => '-a, --all [query]'   ,
        :subtitle     => 'Show all available items' ,
        :autocomplete => "-a #{query}"
      },
    ]
  end

  def cached_feedback?
    @core.cached_feedback?
  end

  def on_feedback
    case options.type
    when :menu, :services
      generate_menu_feedback(options.type)
    when :keyboardmaestro
      generate_keyboardmaestro_feedback
    when :all
      [:menu, :services].each do |type|
        generate_menu_feedback(options.type)
      end
      generate_keyboardmaestro_feedback
    end
  end

  def on_action(arg)
    return unless action?(arg)

    case arg[:type]
    when "keyboardmaestro"
      km_script = %Q{osascript <<__APPLESCRIPT__
      tell application "Keyboard Maestro Engine"
        do script "#{arg[:uid]}"
      end tell
__APPLESCRIPT__}
      system(km_script)
    when 'menu'
      menu_script = %Q{osascript <<__APPLESCRIPT__
      tell application "System Events"
        tell process "#{arg[:application]}"
          tell #{arg[:menu]}
          if (it exists) then
              if (it is enabled) then
                perform action "AXPress"
                return
              else
                return "⛔ Disabled: " & "#{short_menu(arg[:menu]).escape_applescript}"
              end if
            else
              return "🚫 Non-existent: " & "#{short_menu(arg[:menu]).escape_applescript}"
            end if
          end tell
        end tell
      end tell
__APPLESCRIPT__}
      system(menu_script)
    else
      puts "action type #{action_type} is not implemented."
    end

  end


  def on_close
    @local_feedbacks.each do |local_feedback|
      local_feedback.close
    end

    if @settings[:restart?]
      Alfred.search "#{options.keyword} #{@core.user_query.join(' ')}"
    end
  end


  protected

  def short_menu(menu)
    short_menu = menu.scan(/"(.+?)"/).flatten
    short_menu.delete_at(-1)
    short_menu.reverse.join(' ⟩ ')
  end

  def generate_menu_feedback(type = :menu)

    items = MenuItems.generate_items(type)

    application = items[:application]
    application_location = items[:application_location]
    feedback_icon = {:type => "fileicon", :name => application_location}
    sign = '⚫'
    if type.eql? :services
      feedback_icon = {:type => "fileicon", :name => "/Applications/Automator.app"}
      sign = '🔵'
    end

    items[:menus].each do |item|
      if item[:shortcut].empty?
        name = item[:name]
      else
        name = "#{item[:shortcut]} ⟩ #{item[:name]}"
      end

      arg = xml_builder(
        :handler     => @settings[:handler] ,
        :type        => 'menu'              ,
        :application => application         ,
        :menu => item[:line]
      )


      feedback.add_item({
        :title    => "#{name}"                                         ,
        :uid      => "#{application}: #{item[:path]} > #{item[:name]}" ,
        :subtitle => "#{sign} #{application}: #{item[:path]}"          ,
        :arg      => arg,
        :icon     => feedback_icon,
      })
    end
  end



  def generate_keyboardmaestro_feedback
    to_feedback = feedback
    if cached_feedback?
      @keyboardmaestro_feedback = @core.new_feedback(
        :file => File.join(@core.volatile_storage_path ,
                           "#{Alfred.front_appname}-keyboardmaestro.feedback"),
      )

      @local_feedbacks.push @keyboardmaestro_feedback
      to_feedback = @keyboardmaestro_feedback

      if !options.should_reload_cached_feedback and
        @keyboardmaestro_feedback.get_cached_feedback
        feedback.merge! @keyboardmaestro_feedback
        return
      end
    end

    ##
    # **Quit Alfred to load Keyboard Maestro hotkeys**:
    #   gethotkeys from keyboardmaestro.engine does not include the contextual
    #   hot keys for the frontmost application because Alfred take over the
    #   focus.
    global_km_hotkeys = Plist::parse_xml(
      %x{osascript <<__APPLESCRIPT__
        try
          get application id "com.stairways.keyboardmaestro.engine"
        on error err_msg number err_num
          return ""
        end try

        tell application id "com.stairways.keyboardmaestro.engine"
          gethotkeys with asstring
        end tell
__APPLESCRIPT__})

    return unless global_km_hotkeys

    context_km_hotkeys = Plist::parse_xml(
      %x{osascript <<__APPLESCRIPT__
  tell application (path to frontmost application as text) to activate

  tell application id "com.stairways.keyboardmaestro.engine"
    gethotkeys with asstring
  end tell

__APPLESCRIPT__})


    uids = Set.new []
    base_order = 100
    global_km_hotkeys.each do |group|
      group_name = group['name']
      group['macros'].each do |item|
        add_keyboardmaestro_feedback(to_feedback, base_order, group_name, item, '⚪')
        uids.add(item['uid'])
      end
    end

    base_order = 10
    context_km_hotkeys.each do |group|
      group_name = group['name']
      group['macros'].each do |item|
        unless uids.include? item['uid']
          add_keyboardmaestro_feedback(to_feedback, base_order, group_name, item, '🔴')
        end
      end
    end

    @settings[:restart?] = true
  end

  def add_keyboardmaestro_feedback(to_feedback, order, group, item, sign)

    arg = xml_builder(
      :handler => @settings[:handler] ,
      :uid     => item['uid']         ,
      :type    => 'keyboardmaestro'
    )

    feedback_icon = {:type => "fileicon", :name => "/Applications/Keyboard Maestro.app"}
    if item['name']
      to_feedback.add_item({
        :title    => "#{item['key']} ⟩ #{item['name']}",
        :subtitle => "#{sign} Keyboard Maestro: #{group}",
        :uid      => item['uid'] ,
        :arg      => arg,
        :order    => order,
        :icon     => feedback_icon,
        :match?   => :all_title_match?,
      })
    elsif item['namev2']
      to_feedback.add_item({
        :title    => "#{item['triggerstring']} ⟩ #{item['namev2']}",
        :subtitle => "#{sign} Keyboard Maestro: #{group}",
        :uid      => item['uid'] ,
        :arg      => arg,
        :order    => order,
        :icon     => feedback_icon,
        :match?   => :all_title_match?,
      })
    end

  end



end


# main ⟨⟨⟨
# --------


if __FILE__ == $PROGRAM_NAME

  Alfred.with_friendly_error do |alfred|
    alfred.with_rescue_feedback = true
    alfred.with_help_feedback = true

    alfred.cached_feedback_reload_option[:use_reload_option] = true
    alfred.cached_feedback_reload_option[:use_exclamation_mark] = true

    Keylue.new(alfred).register
  end


end



# ⟩⟩⟩

