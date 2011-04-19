class Hotel < ActiveRecord::Base
  acts_as_mappable
  has_many :avails
  has_many :availabilities, :order => "inv_code, limit_on" 
  has_many :stays
  
  def ll
    Geokit::LatLng.new lat,lng
  end
  def self.status(s)
    case s.downcase
    when "open"
      1
    else
      0
    end
  end
end
