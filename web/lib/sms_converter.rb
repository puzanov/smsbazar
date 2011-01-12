class SmsConverter
  def get_converted_sms_text pdu
    sms_text = pdu.short_message
    if pdu.data_coding == 6
      utf8 = Iconv.new("UTF8", "ISO-8859-5") #cyrillic
      sms_text = utf8.iconv(pdu.short_message)
    elsif pdu.data_coding == 8
      utf8 = Iconv.new("UTF8", "UCS-2BE") # ucs big endian
      sms_text = utf8.iconv(pdu.short_message)
    end  
    sms_text 
  end
end
