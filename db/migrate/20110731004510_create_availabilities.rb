class CreateAvailabilities < ActiveRecord::Migration
  def self.up
    drop_table :availabilities
    create_table :availabilities, :force=>true do |t|
      t.integer :hotel_id
      t.integer :avail_id
      t.string :inv_code
      t.string :rate_plan_code
      t.float :rate
      t.date :limit_on
      t.integer :limit
      t.integer :max
      t.integer :gma_user_id

      t.timestamps
    end
  end

  def self.down
    drop_table :availabilities
  end
end
