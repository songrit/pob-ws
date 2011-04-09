class CreateAvailabilities < ActiveRecord::Migration
  def self.up
    create_table :availabilities, :force=>true do |t|
      t.string :hotel_id
      t.string :inv_code
      t.date :limit_on
      t.integer :limit
      t.integer :gma_user_id

      t.timestamps
    end
    add_index :availabilities, :limit_on
    add_index :availabilities, :inv_code
  end

  def self.down
    drop_table :availabilities
  end
end
