desc "SMS Gateway"
task :sms => :environment do
  require "config/environment"
  require "rubygems"
  require "smpp"
  require "lib/sms_gateway"
  begin
    puts "Starting SMS Gateway. Please check the log at #{LOGFILE}"

    # SMPP properties. These parameters work well with the Logica SMPP simulator.
    # Consult the SMPP spec or your mobile operator for the correct settings of
    # the other properties.
    config = {
      :host => SMS_CONFIG['host'],
      :port => SMS_CONFIG['port'],
      :system_id => SMS_CONFIG['login'],
      :password => SMS_CONFIG['password'],
      :system_type => '', # default given according to SMPP 3.4 Spec
      :interface_version => 52,
      :source_ton  => 2,
      :source_npi => 1,
      :destination_ton => 1,
      :destination_npi => 1,
      :source_address_range => '*',
      :destination_address_range => '*',
      :enquire_link_delay_secs => 10
    }
    gw = SampleGateway.new
    gw.start(config)
  rescue Exception => ex
    puts "Exception in SMS Gateway: #{ex} at #{ex.backtrace.join("\n")}"
  end
end

