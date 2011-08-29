class RoomStay < ActiveRecord::Base
  belongs_to :hotel
  belongs_to :booking
  has_many :room_stay_details
end
