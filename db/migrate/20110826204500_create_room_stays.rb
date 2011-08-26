class CreateRoomStays < ActiveRecord::Migration
  def self.up
    create_table :room_stays, :force=>true do |t|
      t.integer :booking_id
      t.integer :hotel_id
      t.string :inv_code
      t.integer :qty
      t.date :start_on
      t.date :end_on
      t.float :total
      t.integer :gma_user_id

      t.timestamps
    end
  end

  def self.down
    drop_table :room_stays
  end
end
