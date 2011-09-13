class AddRateMinToHotels < ActiveRecord::Migration
  def self.up
    add_column :hotels, :rate_min, :float
    add_index :hotels, :code
    add_index :hotels, :rate_min
  end

  def self.down
    remove_column :hotels, :rate_min
    remove_index :hotels, :code
    remove_index :hotels, :rate_min
  end
end
