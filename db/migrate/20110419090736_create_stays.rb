class CreateStays < ActiveRecord::Migration
  def self.up
    create_table :stays, :force=>true do |t|
      t.integer :hotel_id
      t.integer :qty, :default => 0 
      t.float :amount, :default => 0.0
      t.float :tax, :default => 0.0
      t.date :stay_on
      t.integer :gma_user_id

      t.timestamps
    end
  end

  def self.down
    drop_table :stays
  end
end
