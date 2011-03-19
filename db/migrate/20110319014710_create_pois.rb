class CreatePois < ActiveRecord::Migration
  def self.up
    create_table :pois, :force=>true do |t|
      t.string :code
      t.string :name
      t.text :description
      t.float :lat, :precision => 15, :scale => 5
      t.float :lng, :precision => 15, :scale => 5
      t.string :city_code
      t.integer :gma_user_id

      t.timestamps
    end
  end

  def self.down
    drop_table :pois
  end
end
