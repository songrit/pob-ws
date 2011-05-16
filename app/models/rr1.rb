class Rr1 < ActiveRecord::Base
  has_many :rooms
  belongs_to :province
  belongs_to :district
  belongs_to :sub_district
  belongs_to :owner_province, :class_name => "Province"
  belongs_to :owner_district, :class_name => "District"
  belongs_to :owner_sub_district, :class_name => "SubDistrict"
  belongs_to :manager_province, :class_name => "Province"
  belongs_to :manager_district, :class_name => "District"
  belongs_to :manager_sub_district, :class_name => "SubDistrict"
end
