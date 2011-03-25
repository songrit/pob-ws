class CreateLogRequests < ActiveRecord::Migration
  def self.up
    create_table :log_requests, :force=>true do |t|
      t.integer :status
      t.string :ip
      t.text :content
      t.string :request_uri
      t.integer :gma_user_id

      t.timestamps
    end
  end

  def self.down
    drop_table :log_requests
  end
end
