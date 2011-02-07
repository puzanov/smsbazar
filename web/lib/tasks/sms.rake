desc "SMS Gateway"
task :sms => :environment do
  require "config/environment"
  require "rubygems"
  require "smpp"
  require "lib/sms_gateway"
  begin
    puts SMS_CONFIG['host']
    puts "Starting SMS Gateway. Please check the log at #{LOGFILE}"

    # SMPP properties. These parameters work well with the Logica SMPP simulator.
    # Consult the SMPP spec or your mobile operator for the correct settings of
    # the other properties.
    config = {
      :host => '194.152.36.47',
      :port => 2775,
      :system_id => 'namba',
      :password => 'namba123',
      :system_type => '', # default given according to SMPP 3.4 Spec
      :interface_version => 52,
      :source_ton  => 1,
      :source_npi => 0,
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

