require 'test/unit'
#require 'test_helper'
require 'rubygems'
require 'dalli'

class MemcacheTest < Test::Unit::TestCase 
  def test_common
    m = Dalli::Client.new('localhost:11211')
    m.set 'abc', 'xyz'
    from_memcached = m.get 'abc'  
    assert_equal "xyz", from_memcached    
  end
end
