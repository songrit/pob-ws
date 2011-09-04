namespace :pob do
  desc "remove orphaned avail"
  task :clean_orphan=> :environment do
    (Avail.all(:limit=>3).map &:hotel_id).uniq.each do |id|
      next if Hotel.exists?(id)
      Avail.delete_all ['hotel_id=?', id]
    end
    (Availability.all(:limit=>3).map &:hotel_id).uniq.each do |id|
      next if Hotel.exists?(id)
      Availability.delete_all ['hotel_id=?', id]
    end
    (Stay.all(:limit=>3).map &:hotel_id).uniq.each do |id|
      next if Hotel.exists?(id)
      Stay.delete_all ['hotel_id=?', id]
    end
    (MultimediaDescription.all(:limit=>3).map &:hotel_id).uniq.each do |id|
      next if Hotel.exists?(id)
      MultimediaDescription.delete_all ['hotel_id=?', id]
    end
  end
end