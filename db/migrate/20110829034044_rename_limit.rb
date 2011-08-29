class RenameLimit < ActiveRecord::Migration
  def self.up
    rename_column(:availabilities, :limit, :booking_limit)
  end

  def self.down
    rename_column(:availabilities, :booking_limit, :limit)
  end
end
