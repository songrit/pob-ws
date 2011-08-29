class Booking < ActiveRecord::Base
  has_many :room_stays
end
