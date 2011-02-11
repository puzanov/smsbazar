require 'test/unit'
require '../lib/sms_session_tracker'

class SmsSessionTrackerTest < Test::Unit::TestCase 
  def test_save_session
    session_tracker = SmsSessionTracker.new
    sms_session = SmsSession.new
    phone = "phone"
    sms_session.node_id = "node"
    session_tracker.save_session phone, sms_session
    session = session_tracker.get_session phone
    assert_equal "node", session.node_id
  end

  def test_delete_session
    phone = "123"

    session_tracker = SmsSessionTracker.new
    session_tracker.save_session(phone, "test")
    session_tracker.delete_session phone
    session = session_tracker.get_session(phone)

    puts session

  end
end
