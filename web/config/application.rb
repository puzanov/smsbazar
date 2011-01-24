require File.expand_path('../boot', __FILE__)

require "action_controller/railtie"
require "action_mailer/railtie"
require "active_resource/railtie"

# If you have a Gemfile, require the gems listed there, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env) if defined?(Bundler)

module Web
  class Application < Rails::Application
    config.encoding = "utf-8"
    config.filter_parameters += [:password]
    #config.mongoid.logger = Logger.new($stdout, :warn)
  end
end
