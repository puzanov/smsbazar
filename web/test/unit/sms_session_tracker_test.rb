require 'test/unit'
require 'rubygems'
require 'test_helper'
require '../lib/sms_session_tracker'

class SmsSessionTrackerTest < Test::Unit::TestCase 
  def test_save_session
    session_tracker = SmsSessionTracker.new
    phone = "phone"
    node_id = "node"
    session_tracker.save_session phone, node_id
  end
end
