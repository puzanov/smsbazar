require 'test/unit'
require 'rubygems'
require 'test_helper'
require 'mongoid/tree'


class AdvTest < Test::Unit::TestCase 
  def test_adv
    adv = Adv.new
    adv.phone = "996555112233"
    adv.content = "proday mashinu"
    adv.node_id = "4d5a1ee776c66502d0000025"
    adv.city = "Bishkek"
    adv.price = 10000
    adv.ctime = Time.new.to_i
    adv.save
    #adv.destroy
  end
end


