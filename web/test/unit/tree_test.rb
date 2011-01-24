require 'test/unit'
require 'rubygems'
require 'test_helper'
require 'mongoid/tree'


class MenuBrowser
  def get_menu id
    if id.nil?
      id = Tree.root.id.to_s
    end
    node = Tree.root
    node.traverse(:breadth_first) do |n|
      if n.id.to_s == id
        i = 0
        n.children.each do |child|
          i += 1
          puts i.to_s + "-" + child.name
        end
        return n
      end
    end    
  end
end

class TreeTest < Test::Unit::TestCase 
  def test_tree
    mb = MenuBrowser.new
    id = nil
    
    loop do
      node = mb.get_menu id
      i = gets.chomp.to_i
      if i == 0 
        if node.parent.nil?
          puts "the end"
          break
        else
          id = node.parent.id.to_s
        end
      else 
        id = node.children[i-1].id.to_s
      end
    end
  end
end


