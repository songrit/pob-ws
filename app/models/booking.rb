class Booking < ActiveRecord::Base
  belongs_to :hotel
  has_many :room_stays
end
