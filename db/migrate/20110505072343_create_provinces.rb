class CreateProvinces < ActiveRecord::Migration
  def self.up
    create_table :provinces, :force=>true, :options=>'engine=myisam default charset=utf8' do |t|
      t.string :code
      t.string :name
      t.integer :region
    end
  end

  def self.down
    drop_table :provinces
  end
end
