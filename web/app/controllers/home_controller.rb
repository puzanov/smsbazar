class HomeController < ApplicationController
  def index
    begin
      puts "Starting SMS Gateway. Please check the log at #{LOGFILE}"

      # SMPP properties. These parameters work well with the Logica SMPP simulator.
      # Consult the SMPP spec or your mobile operator for the correct settings of
      # the other properties.
      config = {
        :host => '127.0.0.1',
        :port => 11111,
        :system_id => 'test',
        :password => 'test',
        :system_type => '', # default given according to SMPP 3.4 Spec
        :interface_version => 52,
        :source_ton  => 0,
        :source_npi => 1,
        :destination_ton => 1,
        :destination_npi => 1,
        :source_address_range => '',
        :destination_address_range => '',
        :enquire_link_delay_secs => 10
      }
      gw = SampleGateway.new
      gw.start(config)
    rescue Exception => ex
      puts "Exception in SMS Gateway: #{ex} at #{ex.backtrace.join("\n")}"
    end  
  end
end
