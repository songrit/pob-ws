class CreateMultimedias < ActiveRecord::Migration
  def self.up
    create_table :multimedias, :force=>true do |t|
      t.integer :item_id
      t.integer :category
      t.string :caption
      t.text :description
      t.string :version
      t.datetime :create_date_time
      t.integer :unit_of_measure_code
      t.integer :file_size
      t.string :file_name
      t.string :format
      t.string :url
      t.string :title
      t.string :author
      t.string :copyright_notice
      t.boolean :is_original_indicator
      t.integer :width
      t.integer :height
      t.integer :mtype
      t.text :xml
      t.integer :gma_user_id

      t.timestamps
    end
  end

  def self.down
    drop_table :multimedias
  end
end
