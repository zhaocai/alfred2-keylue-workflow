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

def short_menu_text(menu_text)
  short_action_text = menu_text.scan(/"(.+?)"/).flatten
  short_action_text.delete_at(-1)
  short_action_text.reverse.join(' ⟩ ')
end

case action_type
when "keyboardmaestro"
  km_script = %Q{osascript <<__APPLESCRIPT__
  tell application "Keyboard Maestro Engine"
    do script "#{action_text}"
  end tell
__APPLESCRIPT__}
  system(km_script)
when 'menu'
  action_app = feedback_result.root.attributes['application']

  menu_script = %Q{osascript <<__APPLESCRIPT__
	tell application "System Events"
		tell process "#{action_app}"
			tell #{action_text}
				if (it exists) then
					if (it is enabled) then
						perform action "AXPress"
						return
					else
						return "⛔ Disabled: " & "#{short_menu_text(action_text).escape_applescript}"
					end if
				else
						return "🚫 Non-existent: " & "#{short_menu_text(action_text).escape_applescript}"
				end if
			end tell
		end tell
	end tell
__APPLESCRIPT__}
	system(menu_script)
else
  puts "action type #{action_type} is not implemented."
end

