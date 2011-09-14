desc "This task is called by the Heroku cron add-on"
task :cron => :environment do
  # if Time.now.hour % 4 == 0 # run every four hours
  #   puts "Updating feed..."
  #   NewsFeed.update
  #   puts "done."
  # end

  if Time.now.hour == 0 # run at midnight
    ActiveRecord::SessionStore::Session.delete_all(["updated_at < ?", 12.hours.ago])
  end
end
