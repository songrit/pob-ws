class CreateContactInfos < ActiveRecord::Migration
  def self.up
    create_table :contact_infos, :force=>true do |t|
      t.integer :hotel_id
      t.string :address
      t.string :city
      t.string :zip
      t.string :state
      t.string :country
      t.integer :phone_location_type
      t.integer :phone_tech_type
      t.integer :phone_use_type
      t.string :area_city_code
      t.string :country_access_code
      t.string :phone_number
      t.integer :gma_user_id

      t.timestamps
    end
  end

  def self.down
    drop_table :contact_infos
  end
end
