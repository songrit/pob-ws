class CreateAvails < ActiveRecord::Migration
  def self.up
    create_table :avails, :force=>true do |t|
      t.integer :hotel_id
      t.integer :booking_limit
      t.date :start_on
      t.date :end_on
      t.string :rate_plan_code
      t.float :rate
      t.string :inv_code
      t.integer :unique_id
      t.string :unique_id_type
      t.text :multimedias
      t.integer :gma_user_id

      t.timestamps
    end
  end

  def self.down
    drop_table :avails
  end
end
