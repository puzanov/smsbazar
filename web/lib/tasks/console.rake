desc "Console Gateway"
task :console => :environment do
  require "config/environment"
  require "lib/sms_session_tracker"
  require "lib/menu_manager"
  require "lib/menu_browser"
  require "lib/console_io"

  @menu_browser = MenuBrowser.new
  @menu_browser.menu_manager = MenuManager.new
  @menu_browser.io = ConsoleIO.new
  @menu_browser.session_tracker = SmsSessionTracker.new  

  print "Enter your phone number "
  phone = STDIN.gets.chomp
  
  print "Enter your sms message "
  sms = STDIN.gets.chomp

  @menu_browser.process_action phone, sms, nil
end
