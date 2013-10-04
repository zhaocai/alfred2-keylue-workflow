# encoding: UTF-8
require 'yaml'

module MenuItems

  def self.gather_leaves(menu_items)
    leaves = []
    menu_items.each do |menu_item|
      locator = menu_item['locator']
      children = menu_item['children']
      if children
        leaves += gather_leaves(menu_item['children'])
      else
        if locator && locator.length > 0
          leaves << menu_item
        end
      end
    end
    leaves
  end

  # type = :menu or :services
  def generate_items(type = :menu)
    menu_yaml = %x{./bin/menudump --yaml --output #{type.to_s}}
    if $? == 0
      menu_items = YAML.load(menu_yaml)

      menu_leaves = gather_leaves(menu_items['menus'])

      items = []
      menu_leaves.each do |menu_item|
        items << {:name => menu_item['name'],
          :shortcut => menu_item['shortcut'],
          :line => menu_item['locator'],
          :path => menu_item['menuPath']
        }
      end
      app_info = menu_items['application']
      {:menus => items, :application => app_info['name'], :application_location => app_info['bundlePath']}
    else
      parts = menu_yaml.split(/\. /)
      {:menus => [{:name => "Error: #{parts[0]}", :shortcut => "", :line => "", :path => parts[1]}], :application => 'Error', :application_location => 'Error'}
    end
  end

  module_function :generate_items
end

