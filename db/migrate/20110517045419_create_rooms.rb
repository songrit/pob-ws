class CreateRooms < ActiveRecord::Migration
  def self.up
    create_table :rooms, :force=>true do |t|
      t.integer :rr1_id
      t.string :name
      t.integer :qty
      t.integer :gma_user_id

      t.timestamps
    end
  end

  def self.down
    drop_table :rooms
  end
end
