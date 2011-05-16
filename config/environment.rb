# Be sure to restart your server when you modify this file

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.3.5' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require 'thread'
require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
  config.time_zone = 'Bangkok'
  THAI_MONTHS = %w(มกราคม กุมภาพันธ์ มีนาคม เมษายน พฤษภาคม มิถุนายน กรกฎาคม สิงหาคม กันยายน ตุลาคม พฤศจิกายน ธันวาคม)
  APP_VERSION = '1.0'
  config.action_controller.session_store = :active_record_store
  IMAGE_LOCATION = "doc/upload"
  CDN = false
  GMAP = true
  # disable Rails to add timestamp at end of image asset cause problem in heroku
  ENV["RAILS_ASSET_ID"] = ""
  # OTA config
  TARGET = "Test" # or "Production"
  MSG_NEXT = "ดำเนินการต่อ"
end
