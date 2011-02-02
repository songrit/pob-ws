class GmaModule < ActiveRecord::Base
  has_many :gma_services, :order => "seq"
end
