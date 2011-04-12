class CreateAvailabilities < ActiveRecord::Migration
  def self.up
    create_table :availabilities, :force=>true do |t|
      t.integer :hotel_id
      t.string :inv_code
      t.string :rate_plan_code
      t.date :limit_on
      t.integer :limit
      t.integer :gma_user_id

      t.timestamps
    end
  end

  def self.down
    drop_table :availabilities
  end
end
