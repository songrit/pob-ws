class AddFacilityToHotels < ActiveRecord::Migration
  def self.up
    add_column :hotels, :facility, :text
  end

  def self.down
    remove_column :hotels, :facility
  end
end
