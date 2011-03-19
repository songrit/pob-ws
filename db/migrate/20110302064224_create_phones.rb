class CreatePhones < ActiveRecord::Migration
  def self.up
    create_table :phones, :force=>true do |t|
      t.integer :hotel_id
      t.integer :phone_tech_type
      t.string :phone_number
      t.integer :phone_location_type
      t.integer :gma_user_id

      t.timestamps
    end
  end

  def self.down
    drop_table :phones
  end
end
