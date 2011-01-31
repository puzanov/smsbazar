desc "Console Gateway"
task :console => :environment do
  require "config/environment"
  require "rubygems"
  print "Enter your phone number "
  phone = STDIN.gets
  session_tracker = SmsSessionTracker.new
  node_id = session_tracker.get_node_id phone
  puts node_id
end

