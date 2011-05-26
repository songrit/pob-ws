class Rr1 < ActiveRecord::Base
  has_many :rooms
  has_many :rr3s
  belongs_to :province
  belongs_to :district
  belongs_to :sub_district
  belongs_to :owner_province, :class_name => "Province"
  belongs_to :owner_district, :class_name => "District"
  belongs_to :owner_sub_district, :class_name => "SubDistrict"
  belongs_to :manager_province, :class_name => "Province"
  belongs_to :manager_district, :class_name => "District"
  belongs_to :manager_sub_district, :class_name => "SubDistrict"
  
  def full_address
    "#{address} #{street} ตำบล#{sub_district.name} อำเภอ#{district.name} จังหวัด#{province.name}"
  end
end
