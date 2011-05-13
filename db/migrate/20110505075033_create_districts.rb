class CreateDistricts < ActiveRecord::Migration
  def self.up
    create_table :districts, :force=>true, :options=>'engine=myisam default charset=utf8' do |t|
      t.string :code
      t.string :name
      t.string :prefix
      t.float :lat
      t.float :lng
      t.integer :province_id
    end
  end

  def self.down
    drop_table :districts
  end
end
