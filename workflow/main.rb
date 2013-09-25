#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'rubygems' unless defined? Gem # rubygems is only needed in 1.8
($LOAD_PATH << File.expand_path("../lib", __FILE__)).uniq!

require "bundle/bundler/setup"
require "alfred"

load 'menu_items.rb'


def generate_keyboardmaestro_feedback(alfred)
  km_hotkeys = Plist::parse_xml(
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

  return unless km_hotkeys

  feedback = alfred.feedback
  feedback_icon = {:type => "fileicon", :name => "/Applications/Keyboard Maestro.app"}

  km_hotkeys.each do |group|
    group_name = group['name']

    group['macros'].each do |item|
      feedback.add_item({
        :title    => "#{item['key']} ⟩ #{item['name']}",
        :subtitle => "Keyboard Maestro: #{group_name}",
        :uid      => item['uid'] ,
        :arg      => "<action type='keyboardmaestro'>#{item['uid']}</action>",
        :icon     => feedback_icon,
      })
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
      :title    => name                                              ,
      :uid      => "#{application}: #{item[:path]} > #{item[:name]}" ,
      :subtitle => "#{application}: #{item[:path]}"                  ,
      :arg      => "<action application='#{application}' type='menu'>#{item[:line]}</action>",
      :icon     => feedback_icon,
    })
  end

end

def generate_feedback(alfred, query)
  generate_menu_feedback(alfred)
  generate_keyboardmaestro_feedback(alfred)

  alfred.feedback.put_cached_feedback
  puts alfred.feedback.to_alfred(query)
end

Alfred.with_friendly_error do |alfred|
  alfred.with_rescue_feedback = true

  cache_file = File.join(
    alfred.volatile_storage_path,
    "#{Alfred.front_appid}.alfred2feedback")

  alfred.with_cached_feedback do
    use_cache_file(:file => cache_file, :expire => 3600)
  end

  is_refresh = false
  if ARGV[0] == '!'
    is_refresh = true
    ARGV.shift
  end

  if !is_refresh and fb = alfred.feedback.get_cached_feedback
    puts fb.to_alfred(ARGV)
  else
    generate_feedback(alfred, ARGV)
  end
end

