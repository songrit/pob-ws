class Availability < ActiveRecord::Base
  default_scope :order => "limit_on, inv_code"
end
