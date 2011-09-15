class AddRatingToHotels < ActiveRecord::Migration
  def self.up
    add_column :hotels, :rating, :integer
    add_index :hotels, :rating
  end

  def self.down
    remove_column :hotels, :rating
    remove_index :hotels, :rating
  end
end
