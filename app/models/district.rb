class District < ActiveRecord::Base
  belongs_to :province
  has_many :sub_districts
end
