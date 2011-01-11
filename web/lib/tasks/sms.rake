desc "SMS Gateway"
task :sms => :environment do
  require "config/environment"
  require "rubygems"
  require "smpp"
  require "lib/sms"
end

