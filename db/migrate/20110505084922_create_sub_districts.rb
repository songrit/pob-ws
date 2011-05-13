class CreateSubDistricts < ActiveRecord::Migration
  def self.up
    create_table :sub_districts, :force=>true, :options=>'engine=myisam default charset=utf8' do |t|
      t.string :code
      t.string :name
      t.integer :district_id
    end
  end

  def self.down
    drop_table :sub_districts
  end
end
