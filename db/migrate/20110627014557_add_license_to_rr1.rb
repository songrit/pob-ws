class AddLicenseToRr1 < ActiveRecord::Migration
  def self.up
    add_column :rr1s, :license, :string
  end

  def self.down
    remove_column :rr1s, :license
  end
end
