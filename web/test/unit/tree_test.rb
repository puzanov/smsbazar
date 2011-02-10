require 'test/unit'
require 'rubygems'
require 'test_helper'
require 'mongoid/tree'


class AdvTest < Test::Unit::TestCase
  def test_tree
    tree = Tree.new
    tree.name = "root"
    tree.save      
  
    tree = Tree.new
    tree.name = "ba"
    tree.parent_id = "4d5297cc76c6651eb800000d"
    tree.save
  end
end
