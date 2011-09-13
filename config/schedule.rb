# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
set :path, "/home/songrit/apps/elocal"
#
# Learn more: http://github.com/javan/whenever
every 3.hours do
   # command "cd #{path} && heroku db:push postgres://postgres:songrit@localhost/elocal?encoding=utf8 --force"
   command "cd #{path} && git pull github master && bundle && bundle exec rake db:migrate"
   runner "GmaController.new.update_services"
end
