require 'spec_helper'

describe SongritController do
  integrate_views
  it "should update rating" do
    body = File.read('public/OTA/OTA_HotelDescriptiveContentNotifRQ.xml')
    @doc = Nokogiri::XML(body)
    # debugger
    rating= (@doc/'Award').attribute('Rating').try(:value).try(:to_i)
    rating.should==3
  end
end
