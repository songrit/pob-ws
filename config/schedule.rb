# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
set :cron_log, "#{Rails.root}/log/cron.log"
#
every 1.days, :at=>"11:50pm" do
  command "cd #{Rails.root} && heroku db:push postgres://postgres:songrit@localhost/elocal?encoding=utf8 --force"
  command "shutdown now -P"
  #runner "AnotherModel.prune_old_records"
end

# Learn more: http://github.com/javan/whenever
