class CreatePois < ActiveRecord::Migration
  def self.up
    create_table :pois, :force=>true do |t|
      t.string :code
      t.string :name
      t.text :description
      t.decimal :lat, :precision => 15, :scale => 5
      t.decimal :lng, :precision => 15, :scale => 5
      t.string :city_code
      t.integer :gma_user_id

      t.timestamps
    end
    add_index :pois, :name
  end

  def self.down
    drop_table :pois
  end
end
