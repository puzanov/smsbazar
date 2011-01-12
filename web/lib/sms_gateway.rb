require "net/http"
require "uri"
require 'iconv'
require 'sms_converter'

LOGFILE = "/tmp/sms_gateway.log"
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
    
    sc = SmsConverter.new
    sms_text sc.get_converted_sms_text pdu
    
    adv = Adv.new
    adv.phone = pdu.source_addr
    adv.content = sms_text
    adv.save
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


