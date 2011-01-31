desc "Console Gateway"
task :add => :environment do
  require "config/environment"
  require "lib/sms_session_tracker"
  require "lib/menu_browser"

  session_tracker = SmsSessionTracker.new
  menu_browser = MenuBrowser.new 

  print "Enter your phone number "
  phone = STDIN.gets.chomp
  
  print "Enter your sms message "
  sms = STDIN.gets.chomp
 
  session = session_tracker.get_session phone.to_s
  if session == nil 
    menu_item = menu_browser.get_root
    puts menu_item.menu_text_items
  else
    node_id = session.node_id
    node = menu_browser.get_node node_id
    menu_item =  menu_browser.get_menu_by_item_number node, sms.to_i   
    if menu_item.node.leaf?
      if session.put_adv
        adv = Adv.new
        adv.content = sms
        adv.phone = phone
        adv.node_id = menu_item.node.id.to_s
        adv.save
        puts "Спасибо блин большое!"
      else
        puts "Напишите объявление"
        put_adv = 1
      end
    else
      puts menu_item.menu_text_items
    end
  end
  sms_session = SmsSession.new
  sms_session.put_adv = put_adv 
  sms_session.node_id = menu_item.node.id.to_s
  session_tracker.save_session phone, sms_session
end
