# Load the rails application
require File.expand_path('../application', __FILE__)
# Initialize the rails application
Web::Application.initialize!
SMS_CONFIG = YAML.load_file("#{RAILS_ROOT}/config/sms.yml")
