class AddDistrictIdToRr3 < ActiveRecord::Migration
  def self.up
    add_column :rr3s, :district_id, :integer
    Rr3.all.each do |r|
      r.update_attribute :district_id, r.rr1.district_id
    end
  end

  def self.down
    remove_column :rr3s, :district_id
  end
end
