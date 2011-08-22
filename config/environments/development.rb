# Settings specified here will take precedence over those in config/environment.rb

# In the development environment your application's code is reloaded on
# every request.  This slows down response time but is perfect for development
# since you don't have to restart the webserver when you make code changes.

# error nilinclude? see http://www.theirishpenguin.com/2009/01/22/bug-of-the-day-nilinclude-error-with-create_time_zone_conversion_attribute/
config.cache_classes = true

# Log error messages when you accidentally call methods on nil.
config.whiny_nils = true

# Show full error reports and disable caching
#config.action_controller.consider_all_requests_local = false
config.action_controller.consider_all_requests_local = true
config.action_view.debug_rjs                         = true
config.action_controller.perform_caching             = false
config.reload_plugins = true

# Don't care if the mailer can't send
config.action_mailer.raise_delivery_errors = false

#config.gem "yaml_db"
