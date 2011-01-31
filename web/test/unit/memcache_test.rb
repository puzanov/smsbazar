require 'test/unit'
require 'rubygems'
require 'test_helper'
require 'memcache'

class MemcacheTest < Test::Unit::TestCase 
  def test_common
    m = MemCache.new('localhost:11211')
    m.set 'abc', 'xyz'
    from_memcached = m.get 'abc'  
    assert_equal "xyz", from_memcached    
  end
end
