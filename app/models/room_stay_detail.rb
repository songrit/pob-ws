class RoomStayDetail < ActiveRecord::Base
  belongs_to :room_stay
  
  def price
    rate*qty
  end
end
