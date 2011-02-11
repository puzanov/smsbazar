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

  def convert_text sms_text, pdu
    #if pdu.data_coding == 6
    #  utf8 = Iconv.new("ISO-8859-5", "UTF8") #cyrillic
    #  sms_text = utf8.iconv(sms_text)
    #elsif pdu.data_coding == 8
      utf8 = Iconv.new("UCS-2BE", "UTF8") # ucs big endian
      sms_text = utf8.iconv(sms_text)
    #end
    sms_text
  end
end
