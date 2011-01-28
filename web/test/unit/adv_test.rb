require 'test/unit'
require 'rubygems'
require 'test_helper'
require 'mongoid/tree'


class AdvTest < Test::Unit::TestCase 
  def test_adv
    adv = Adv.new
    adv.phone = "996555112233"
    adv.content = "proday mashinu"
    adv.node_id = "4d3d0ec41d41c8099c000001"
    adv.city = "Bishkek"
    adv.price = 10000
    adv.save
  end
end


