class CreateHotels < ActiveRecord::Migration
  def self.up
    create_table :hotels, :force=>true do |t|
      t.string :code
      t.string :name
      t.string :hotel_short_name
      t.string :hotel_code_context
      t.string :time_zone
      t.string :brand_code
      t.string :brand_name
      t.string :currency_code
      t.date :info_updated_on
      t.integer :hotel_status_code
      t.integer :built
      t.float :latitude
      t.float :longitude
      t.integer :location_category
      t.integer :segment_category
      t.integer :hotel_category
      t.text :address
      t.string :city_name
      t.string :postal_code
      t.string :county
      t.string :state_prov
      t.string :country_name
      t.string :url
      t.text :description
      t.integer :gma_user_id

      t.timestamps
    end
  end

  def self.down
    drop_table :hotels
  end
end
