desc "Console Gateway"
task :console => :environment do
  require "config/environment"
  require "lib/sms_session_tracker"
  require "lib/menu_manageer"
  require "lib/console_io"

  session_tracker = SmsSessionTracker.new
  menu_browser = MenuManager.new 
  io = ConsoleIO.new

  print "Enter your phone number "
  phone = STDIN.gets.chomp
  
  print "Enter your sms message "
  sms = STDIN.gets.chomp
 
  session = session_tracker.get_session phone.to_s
  if session == nil 
    menu_item = menu_browser.get_root
    io.print menu_item.menu_text_items
  else
    node_id = session.node_id
    node = menu_browser.get_node node_id
    menu_item =  menu_browser.get_menu_by_item_number node, sms.to_i   
    if menu_item.node.leaf?
      advs = menu_browser.get_advs menu_item.node
      advs.each do |adv|
        io.print "#{adv.content}. Телефон #{adv.phone}"
      end
    else
      io.print menu_item.menu_text_items
    end
  end
  sms_session = SmsSession.new
  sms_session.node_id = menu_item.node.id.to_s
  session_tracker.save_session phone, sms_session
end
