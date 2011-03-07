require "net/http"
require "uri"
require 'iconv'
require 'sms_converter'
require "sms_session_tracker"
require "menu_manager"
require "menu_browser"
require "sms_io"
require "yaml"

LOGFILE = "/tmp/sms_gateway.log"
Smpp::Base.logger = Logger.new(LOGFILE)

class SampleGateway
  
  # MT id counter. 
  @@mt_id = 0
  @@long_messages = Hash.new
  
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
    puts "Data coding #{pdu.data_coding}"
    sc = SmsConverter.new
    begin
      if pdu.udh.kind_of?(Array)
        if pdu.udh.length == 6 && pdu.udh[1] == 0
          if pdu.udh[4] != pdu.udh[5]
            if @@long_messages[pdu.udh[3]].nil?
              @@long_messages[pdu.udh[3]] = pdu.short_message
            else
              @@long_messages[pdu.udh[3]] = @@long_messages[pdu.udh[3]] + pdu.short_message
            end
            return
          else
            @@long_messages[pdu.udh[3]] = @@long_messages[pdu.udh[3]] + pdu.short_message
            sms_text = sc.convert_long_text @@long_messages[pdu.udh[3]]
            @@long_messages.delete(pdu.udh[3])
          end
        end
      else
        sms_text = sc.get_converted_sms_text pdu
      end
      @menu_browser = MenuBrowser.new
      @menu_browser.menu_manager = MenuManager.new
      @menu_browser.io = self
      @menu_browser.session_tracker = SmsSessionTracker.new
      @menu_browser.process_action(pdu.source_addr, sms_text, pdu)
    rescue => exception
      puts $!
      puts exception.backtrace
    end
  end

  def send phone, data, pdu
    data = data.join("\n") if data.class == Array

    config = {
     :service_type => 1,
     :source_addr_ton => 2,
     :source_addr_npi => 1,
     :dest_addr_ton => 1,
     :dest_addr_npi => 1,
     :esm_class => 3 ,
     :protocol_id => 0,
     :priority_flag => 0,
     :schedule_delivery_time => nil,
     :validity_period => nil,
     :registered_delivery=> 1,
     :replace_if_present_flag => 0,
     :data_coding => 8,
     :sm_default_msg_id => 0
    }

    sc = SmsConverter.new
    puts data
    sms_to_send = sc.convert_text(data, pdu)
    puts sms_to_send
    SampleGateway.send_mt("1172", phone, sms_to_send, config)    

  end

  def delivery_report_received(transceiver, pdu)
    puts "Delegate: delivery_report_received: ref #{pdu.msg_reference} stat #{pdu.stat}"
  end

  def message_accepted(transceiver, mt_message_id, pdu)
    puts "Delegate: message_accepted: id #{mt_message_id} smsc ref id: #{pdu.message_id}"
  end

  def message_rejected(transceiver, mt_message_id, pdu)
    puts pdu.inspect
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


