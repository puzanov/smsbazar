require 'test/unit'
require 'sms_converter'
require 'yaml'
require 'rubygems'
require 'smpp'
require 'colorize'

class ConvTest < Test::Unit::TestCase 
  def test_cyrillic
    pdu = YAML::load File.open('unit/pdus/pdu6') 
    sc = SmsConverter.new
    sms_text = sc.get_converted_sms_text pdu
    assert_equal "привет", sms_text 
  end
  def test_ucs2
    pdu = YAML::load File.open('unit/pdus/pdu8') 
    sc = SmsConverter.new
    sms_text = sc.get_converted_sms_text pdu
    assert_equal "привет", sms_text 
  end
end
