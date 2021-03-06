require 'test/unit'
require 'rubygems'
require 'test_helper'
require 'mongoid'
require 'mongoid/tree'
require '../lib/menu_manager'

class MenuManagerTest < Test::Unit::TestCase 
  def test_get_item_from_root_menu
    mb = MenuManager.new

    menu_item = mb.get_root
    parent = menu_item.node    
    
    m = mb.get_menu_by_item_number parent, 1
    m1 = mb.get_menu_by_item_number m.node, 1
    m2 = mb.get_menu_by_item_number m1.node, 1
    m3 = mb.get_menu_by_item_number m2.node, 1
  
    if m3.is_leaf 
      advs = mb.get_advs m3.node
      advs.each do |adv|
        puts adv.content
      end
      #assert_equal "proday mashinu", adv.content
    end
  end
end
