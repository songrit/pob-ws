class CreateRr1s < ActiveRecord::Migration
  def self.up
    create_table :rr1s, :force=>true do |t|
      t.string :at
      t.string :hotel_name
      t.string :address
      t.string :street
      t.integer :sub_district_id
      t.integer :district_id
      t.integer :province_id
      t.string :phone
      t.string :owner_name
      t.date :owner_dob
      t.string :owner_citizen
      t.string :owner_national
      t.string :owner_address
      t.string :owner_street
      t.integer :owner_sub_district_id
      t.integer :owner_district_id
      t.integer :owner_province_id
      t.string :owner_phone
      t.string :manager_name
      t.date :manager_dob
      t.string :manager_citizen
      t.string :manager_national
      t.string :manager_address
      t.string :manager_street
      t.integer :manager_sub_district_id
      t.integer :manager_district_id
      t.integer :manager_province_id
      t.string :manager_phone
      t.string :doc
      t.integer :brochure
      t.string :code
      t.float :lat
      t.float :lng
      t.integer :gma_user_id

      t.timestamps
    end
  end

  def self.down
    drop_table :rr1s
  end
end
