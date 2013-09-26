#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'rubygems' unless defined? Gem # rubygems is only needed in 1.8
($LOAD_PATH << File.expand_path("../lib", __FILE__)).uniq!

require "bundle/bundler/setup"
require "alfred"
require 'set'

load 'menu_items.rb'


def add_keyboardmaestro_feedback(feedback, group, item, sign)
  feedback_icon = {:type => "fileicon", :name => "/Applications/Keyboard Maestro.app"}
  if item['name']
    feedback.add_item({
      :title    => "#{item['key']} ⟩ #{item['name']}",
      :subtitle => "#{sign} Keyboard Maestro: #{group}",
      :uid      => item['uid'] ,
      :arg      => "<action type='keyboardmaestro'>#{item['uid']}</action>",
      :icon     => feedback_icon,
    })
  elsif item['namev2']
    feedback.add_item({
      :title    => "#{item['triggerstring']} ⟩ #{item['namev2']}",
      :subtitle => "#{sign} Keyboard Maestro: #{group}",
      :uid      => item['uid'] ,
      :arg      => "<action type='keyboardmaestro'>#{item['uid']}</action>",
      :icon     => feedback_icon,
    })
  end

end

def generate_keyboardmaestro_feedback(alfred)
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


  feedback = alfred.feedback

  uids = Set.new []
  global_km_hotkeys.each do |group|
    group_name = group['name']
    group['macros'].each do |item|
      add_keyboardmaestro_feedback(feedback, group_name, item, '⚪')
      uids.add(item['uid'])
    end
  end

  context_km_hotkeys.each do |group|
    group_name = group['name']
    group['macros'].each do |item|
      unless uids.include? item['uid']
        add_keyboardmaestro_feedback(feedback, group_name, item, '🔴')
      end
    end
  end

end


def generate_menu_feedback(alfred)

  feedback = alfred.feedback
  items = MenuItems.generate_items

  application = items[:application]
  application_location = items[:application_location]
  feedback_icon = {:type => "fileicon", :name => application_location}

  items[:menus].each do |item|
    if item[:shortcut].empty?
      name = item[:name]
    else
      name = "#{item[:shortcut]} ⟩ #{item[:name]}"
    end

    feedback.add_item({
      :title    => "#{name}"                                         ,
      :uid      => "#{application}: #{item[:path]} > #{item[:name]}" ,
      :subtitle => "⚫ #{application}: #{item[:path]}"                  ,
      :arg      => "<action application='#{application}' type='menu'>#{item[:line]}</action>",
      :icon     => feedback_icon,
    })
  end

end


def generate_feedback(alfred, query)
  generate_menu_feedback(alfred)
  generate_keyboardmaestro_feedback(alfred)

  alfred.feedback.put_cached_feedback
  # puts alfred.feedback.to_alfred(query)
end


# Overwrite default query matcher
module Alfred
  class Feedback::Item
    def match?(query)
      all_title_match?(query)
    end
  end
end


# main ⟨⟨⟨
# --------

keyword = ARGV.shift

Alfred.with_friendly_error do |alfred|
  alfred.with_rescue_feedback = true

  cache_file = File.join(
    alfred.volatile_storage_path,
    "#{Alfred.front_appid}.alfred2feedback")

  alfred.with_cached_feedback do
    use_cache_file(:file => cache_file)
  end

  is_refresh = false
  if ARGV[0].eql?('!')
    is_refresh = true
    ARGV.shift
  elsif ARGV[-1].eql?('!')
    is_refresh = true
    ARGV.delete_at(-1)
  end

  if !is_refresh and fb = alfred.feedback.get_cached_feedback
    puts fb.to_alfred(ARGV)
  else
    generate_feedback(alfred, ARGV)
    Alfred.search "#{keyword} #{ARGV.join(' ')}"
  end
end


# ⟩⟩⟩

