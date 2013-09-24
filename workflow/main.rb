#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'rubygems' unless defined? Gem # rubygems is only needed in 1.8
($LOAD_PATH << File.expand_path("../lib", __FILE__)).uniq!

require "bundle/bundler/setup"
require "alfred"

load 'menu_items.rb'

require 'benchmark'

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
      :arg      => item[:line]                                       ,
      :icon     => feedback_icon,
    })
  end

end

def generate_feedback(alfred, query)
  generate_menu_feedback(alfred)

  alfred.feedback.put_cached_feedback
  puts alfred.feedback.to_alfred(query)
end

Alfred.with_friendly_error do |alfred|
  alfred.with_rescue_feedback = true

  cache_file = File.join(
    alfred.volatile_storage_path,
    "#{Alfred.front_appid}.alfred2feedback")

  alfred.with_cached_feedback do
    use_cache_file(:file => cache_file, :expire => 86400)
  end

  is_refresh = false
  if ARGV[0] == '!'
    is_refresh = true
    ARGV.shift
  end

  # alfred.ui.debug(cache_file)
  if !is_refresh and fb = alfred.feedback.get_cached_feedback
    # alfred.ui.debug("CachedFeedback")
    puts fb.to_alfred(ARGV)
  else
    generate_feedback(alfred, ARGV)
  end
end

