class SmsIO
  require "lib/sms_gateway"
  def send data
    SampleGateway.send_mt("996700527133", "1172", "halo", {
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
     :data_coding => 0,
     :sm_default_msg_id => 0
     })
  end
end
