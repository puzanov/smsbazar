require 'test/unit'
require 'yaml'
require 'rubygems'
require "bundler"
Bundler.require(:test_converter)
require 'lib/sms_converter'

class ConvTest < Test::Unit::TestCase 
  def test_cyrillic
    pdu = YAML::load File.open('test/unit/pdus/pdu6') 
    sc = SmsConverter.new
    sms_text = sc.get_converted_sms_text pdu
    assert_equal "привет", sms_text 
  end
  def test_ucs2
    pdu = YAML::load File.open('test/unit/pdus/pdu8') 
    sc = SmsConverter.new
    sms_text = sc.get_converted_sms_text pdu
    assert_equal "привет", sms_text 
  end
end
