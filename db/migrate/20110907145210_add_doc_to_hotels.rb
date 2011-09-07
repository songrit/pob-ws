class AddDocToHotels < ActiveRecord::Migration
  def self.up
    add_column :hotels, :doc, :text
  end

  def self.down
    remove_column :hotels, :doc
  end
end
