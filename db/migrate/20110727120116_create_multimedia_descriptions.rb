class CreateMultimediaDescriptions < ActiveRecord::Migration
  def self.up
    create_table :multimedia_descriptions, :force=>true do |t|
      t.integer :hotel_id
      t.text :xml
      t.integer :gma_user_id

      t.timestamps
    end
  end

  def self.down
    drop_table :multimedia_descriptions
  end
end
