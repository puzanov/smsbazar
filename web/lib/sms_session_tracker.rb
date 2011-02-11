require 'rubygems'
require 'dalli'

class SmsSessionTracker
  def get_session phone
    m = Dalli::Client.new('localhost:11211')
    session = m.get phone
    return session
  end
  
  def save_session phone, session
    m = Dalli::Client.new('localhost:11211')
    m.set phone, session
  end

  def delete_session phone
    m = Dalli::Client.new('localhost:11211')
    m.delete phone
  end
end

class SmsSession
  attr_accessor :node_id, :put_adv
end

