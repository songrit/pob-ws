class AddApiKeyToGmaUsers < ActiveRecord::Migration
  def self.up
    add_column :gma_users, :api_key, :string
  end

  def self.down
    remove_column :gma_users, :api_key
  end
end
