class Province < ActiveRecord::Base
  has_many :districts
end
