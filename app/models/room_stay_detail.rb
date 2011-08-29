class RoomStayDetail < ActiveRecord::Base
  belongs_to :room_stay
  default_scope :order=>"stay_on"
  
  def price
    rate*qty
  end
end
