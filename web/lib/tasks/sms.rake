desc "SMS Gateway"
task :sms => :environment do
  require "config/environment"
  require "lib/sms"
end

