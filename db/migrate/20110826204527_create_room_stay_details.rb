class CreateRoomStayDetails < ActiveRecord::Migration
  def self.up
    create_table :room_stay_details, :force=>true do |t|
      t.integer :room_stay_id
      t.date :stay_on
      t.float :rate
      t.integer :qty
      t.integer :gma_user_id

      t.timestamps
    end
  end

  def self.down
    drop_table :room_stay_details
  end
end
