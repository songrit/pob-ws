class CreateBookings < ActiveRecord::Migration
  def self.up
    create_table :bookings, :force=>true do |t|
      t.integer :hotel_id
      t.string :hotel_code
      t.date :start_on
      t.text :reservation
      t.integer :gma_user_id

      t.timestamps
    end
  end

  def self.down
    drop_table :bookings
  end
end
