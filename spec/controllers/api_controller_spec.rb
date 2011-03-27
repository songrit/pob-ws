require 'spec_helper'

describe ApiController do

  it "HotelDescriptiveContentNotif should create new Hotel" do
    body= File.open("public/OTA/OTA_HotelDescriptiveContentNotifRQ.xml").read
    lambda do 
      request.env['content_type'] = 'application/xml' 
      request.env['RAW_POST_DATA'] =  body
      post :hotel_descriptive_content_notif
    end.should change(Hotel, :count).by(1)
  end
  it "HotelDescriptiveContentNotif should not create existing Hotel" do
    body= File.open("public/OTA/OTA_HotelDescriptiveContentNotifRQ.xml").read
    request.env['content_type'] = 'application/xml' 
    request.env['RAW_POST_DATA'] =  body
    post :hotel_descriptive_content_notif
    lambda do 
      request.env['content_type'] = 'application/xml' 
      request.env['RAW_POST_DATA'] =  body
      post :hotel_descriptive_content_notif
    end.should_not change(Hotel, :count)
  end
  it "HotelDescriptiveContentNotif should update existing Hotel" do
    body= File.open("public/OTA/OTA_HotelDescriptiveContentNotifRQ.xml").read
    request.env['content_type'] = 'application/xml' 
    request.env['RAW_POST_DATA'] =  body
    post :hotel_descriptive_content_notif
    hotel= Hotel.last
    id= hotel.id
    hotel.name.should == "Boston Marriott Copley Place"
    lambda do 
      body= File.open("public/OTA/OTA_HotelDescriptiveContentNotifRQ1.xml").read
      request.env['content_type'] = 'application/xml' 
      request.env['RAW_POST_DATA'] =  body
      post :hotel_descriptive_content_notif
    end.should_not change(Hotel, :count)
    hotel= Hotel.find id
    hotel.name.should == "Songrit"
  end

end
