class Hotel < ActiveRecord::Base
  acts_as_mappable :default_units => :kms
  has_many :avails
  has_many :availabilities, :order => "inv_code, limit_on" 
  has_many :stays
  has_many :contact_infos
  has_many :multimedia_descriptions
  has_many :bookings

  def update_avail(inv_code, start_on, end_on, number_of_units)
    start_on.step(end_on) do |d|
      availability= Availability.last(:conditions=>['inv_code=? AND limit_on=? AND hotel_id=?',inv_code, d, id])
      availability.booking_limit -= number_of_units
      availability.save
    end
  end
  def check_avail?(inv_code, start_on, end_on, number_of_units)
    avail= true
    start_on.step(end_on-1) do |d|
      availability= Availability.last(:conditions=>['inv_code=? AND limit_on=? AND hotel_id=?',inv_code, d, id])
      if availability
        avail= false if (availability.booking_limit < number_of_units)
      else
        avail= false
      end
    end
    avail
  end
  def rate(inv_code,d)
    a= (Availability.all :conditions=>{:hotel_id=>id,:limit_on=>d, :inv_code=>inv_code}).last
    if a
      a.rate
    else
      "N/A"
    end
  end
  def ll
    Geokit::LatLng.new lat,lng
  end
  def self.status(s)
    case s.try(:downcase)
    when "open"
      1
    else
      0
    end
  end
end
