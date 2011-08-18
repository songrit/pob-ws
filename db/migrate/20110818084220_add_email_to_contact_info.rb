class AddEmailToContactInfo < ActiveRecord::Migration
  def self.up
    add_column :contact_infos, :email, :string
  end

  def self.down
    remove_column :contact_infos, :email
  end
end
