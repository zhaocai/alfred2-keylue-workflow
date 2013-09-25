#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'rubygems' unless defined? Gem # rubygems is only needed in 1.8
($LOAD_PATH << File.expand_path("../lib", __FILE__)).uniq!

require "bundle/bundler/setup"

require "rexml/document"


class String
  def escape_applescript
    gsub(/(?=["\\])/, '\\')
  end
end


feedback_result = REXML::Document.new ARGV[0]
action_type = feedback_result.root.attributes['type']
action_text = feedback_result.root.get_text.value

case action_type
when "keyboardmaestro"
  %x{osascript <<__APPLESCRIPT__
  tell application "Keyboard Maestro Engine"
    do script "#{action_text}"
  end tell
__APPLESCRIPT__}
when 'menu'
  action_app = feedback_result.root.attributes['application']
  %x{osascript <<__APPLESCRIPT__
	tell application "System Events"
		tell process "#{action_app}"
			tell #{action_text}
				if (it exists) then perform action "AXPress"
			end tell
		end tell
	end tell
__APPLESCRIPT__}
else
  puts "action type #{action_type} is not implemented."
end
