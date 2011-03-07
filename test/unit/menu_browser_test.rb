require 'test/unit'
require 'rubygems'
require 'test_helper'
require 'mongoid'
require 'mongoid/tree'
require '../lib/menu_manager'
require '../lib/menu_browser'
require '../lib/console_io'
require '../lib/sms_session_tracker'

class MenuBrowserTest < Test::Unit::TestCase 
  def test_browser
    phone = "1122334"
    message = ""
    
    m = Dalli::Client.new('localhost:11211')
    m.delete phone
    
    mm = MenuManager.new
    io = ConsoleIO.new
    mb = MenuBrowser.new
    st = SmsSessionTracker.new
    mb.menu_manager = mm
    mb.io = io
    mb.session_tracker = st
    
    mb.process_action phone, message
    mb.process_action phone, 1
    mb.process_action phone, 1
  end
end
