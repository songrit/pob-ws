class CreateGuestRooms < ActiveRecord::Migration
  def self.up
    create_table :guest_rooms, :force=>true do |t|
      t.integer :hotel_id
      t.string :code
      t.string :name
      t.string :gid
      t.integer :bed_type_code
      t.string :code_context
      t.integer :max_occupancy
      t.integer :max_adult_occupancy
      t.integer :quantity
      t.integer :non_smoking_quantity
      t.integer :room_amenity_code
      t.date :info_updated_on
      t.integer :gma_user_id

      t.timestamps
    end
  end

  def self.down
    drop_table :guest_rooms
  end
end
