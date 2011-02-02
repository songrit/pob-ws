require 'smtp_tls'

ActionMailer::Base.smtp_settings = {
	:address => "smtp.gmail.com",
	:port => 587,
	:authentication => :plain,
	:domain => "xxx@gmail.com",
	:user_name => "xxx@gmail.com",
	:password => "xxx"
}
