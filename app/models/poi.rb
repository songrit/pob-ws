class Poi < ActiveRecord::Base
  # always save name as upcase
  def name=(s)
    write_attribute "name", s.upcase
  end
  def city_code=(s)
    write_attribute "city_code", s.upcase
  end
  def ll
    Geokit::LatLng.new lat,lng
  end
end
