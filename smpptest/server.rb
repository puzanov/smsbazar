#!/usr/bin/env ruby

require 'rubygems'
require 'smpp'
require "net/http"
require "uri"

LOGFILE = File.dirname(__FILE__) + "/sms_gateway.log"
Smpp::Base.logger = Logger.new(LOGFILE)

class SampleGateway
  
  # MT id counter. 
  @@mt_id = 0
  
  # expose SMPP transceiver's send_mt method
  def self.send_mt(*args)
    @@mt_id += 1
    @@tx.send_mt(@@mt_id, *args)
  end
    
  def start(config)
    # The transceiver sends MT messages to the SMSC. It needs a storage with Hash-like
    # semantics to map SMSC message IDs to your own message IDs.
    pdr_storage = {} 

    # Run EventMachine in loop so we can reconnect when the SMSC drops our connection.
    puts "Connecting to SMSC..."
    loop do
      EventMachine::run do             
        @@tx = EventMachine::connect(
          config[:host], 
          config[:port], 
          Smpp::Transceiver, 
          config, 
          self    # delegate that will receive callbacks on MOs and DRs and other events
        )     
      end
      puts "Disconnected. Reconnecting in 5 seconds.."
      sleep 5
    end
  end
  
  # ruby-smpp delegate methods 

  def mo_received(transceiver, pdu)
    puts "Delegate: mo_received: from #{pdu.source_addr} to #{pdu.destination_addr}: #{pdu.short_message}"

    Net::HTTP.start('192.168.8.119', 3000) do |http|
      data = "<adv><phone>123</phone><content>#{pdu.short_message}</content></adv>"
      headers = {
        'Content-type' => 'text/xml'
      }
      response = http.post('/advs', data, headers); 
      puts "Code: #{response.code}" 
    end

response = http.request(request)
  end

  def delivery_report_received(transceiver, pdu)
    puts "Delegate: delivery_report_received: ref #{pdu.msg_reference} stat #{pdu.stat}"
  end

  def message_accepted(transceiver, mt_message_id, pdu)
    puts "Delegate: message_accepted: id #{mt_message_id} smsc ref id: #{pdu.message_id}"
  end

  def message_rejected(transceiver, mt_message_id, pdu)
    puts "Delegate: message_rejected: id #{mt_message_id} smsc ref id: #{pdu.message_id}"
  end

  def bound(transceiver)
    puts "Delegate: transceiver bound"
  end

  def unbound(transceiver)  
    puts "Delegate: transceiver unbound"
    EventMachine::stop_event_loop
  end
  
end

# Start the Gateway
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
