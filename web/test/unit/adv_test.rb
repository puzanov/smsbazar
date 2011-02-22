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
    adv.destroy
  end

  def test_migrate
    advs = Adv.find :all
    advs.each do |adv|
      new_adv = Adv.new
      new_adv.phone = adv.phone
      new_adv.content = adv.content
      new_adv.node_id = adv.node_id
      new_adv.city = adv.city
      new_adv.price = adv.price
      new_adv.ctime = adv.ctime
      adv.destroy
      new_adv.save
    end
  end
end


