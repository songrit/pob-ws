class AddPrecision < ActiveRecord::Migration
  def self.up
    change_column :hotels, :lat, :decimal, :precision => 25, :scale=>15
    change_column :hotels, :lng, :decimal, :precision => 25, :scale=>15
    change_column :pois, :lat, :decimal, :precision => 25, :scale=>15
    change_column :pois, :lng, :decimal, :precision => 25, :scale=>15
  end

  def self.down
  end
end
