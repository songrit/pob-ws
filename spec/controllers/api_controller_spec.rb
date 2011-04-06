require 'spec_helper'

describe ApiController do
  integrate_views

  describe "Ping" do
    it "should handle OTA_Ping" do
      @body= File.open("public/OTA/OTA_PingRQ.xml").read
      @doc = Nokogiri::XML(@body)
      echo = @doc.xpath('//xmlns:EchoData').text
      request.env['content_type'] = 'application/xml'
      request.env['RAW_POST_DATA'] =  @body
      post :ping
      puts response.body
      # leading and trailing space in data will be stripped
      response.should have_tag("EchoData", echo.strip) 
    end
  end
  describe "HotelSearch" do
    before do
      Hotel.delete_all
      @body= File.open("public/OTA/OTA_HotelDescriptiveContentNotifRQ.xml").read
      request.env['content_type'] = 'application/xml'
      request.env['RAW_POST_DATA'] =  @body
      post :hotel_descriptive_content_notif
    end
    it "should search by coordinates" do
      body = File.read("public/OTA/OTA_HotelSearchRQ1.xml")
      # body = File.open("public/OTA/OTA_HotelSearchRQ.xml").read
      request.env['content_type'] = 'application/xml'
      request.env['RAW_POST_DATA'] = body
      post :hotel_search
      response.should have_tag("Success")
      response.should have_tag("Property[HotelCode='BOSCO']")
    end
    it "should provide only available hotels"
    it "should include availability info in the attribute"
  end
  
  describe "HotelRateAmountNotif" do
    it "should handle HotelRateAmountNotifRQ/RS"
  end

  describe "HotelAvail" do
    before do
      body= File.open("public/OTA/OTA_HotelAvailRQ100.xml").read
      request.env['content_type'] = 'application/xml'
      request.env['RAW_POST_DATA'] =  body
      post :hotel_avail
    end
    it "should assign hotel codes" do
      assigns[:hotel_codes].should == ['BOSCO','LONSU','LONHB']
    end
    it "should assign date range" do
      assigns[:start_on].should == Date.new(2004,8,2)
      assigns[:end_on].should == Date.new(2004,8,3)
    end
    it "should find available hotels"
  end

  describe "HotelAvailNotif" do
    integrate_views
    it "should handle OTA_HotelAvailNotifRQ" do
      body= File.open("public/OTA/OTA_HotelDescriptiveContentNotifRQ.xml").read
      request.env['content_type'] = 'application/xml'
      request.env['RAW_POST_DATA'] =  body
      post :hotel_descriptive_content_notif
      lambda do
        body= File.open("public/OTA/OTA_HotelAvailNotifRQ.xml").read
        request.env['content_type'] = 'application/xml'
        request.env['RAW_POST_DATA'] =  body
        post :hotel_avail_notif
      end.should change(Avail, :count)
      response.should have_tag("Success")
    end
  end
  
  describe "HotelDescriptiveContentNotif" do
    before do
      Hotel.delete_all
      @body= File.open("public/OTA/OTA_HotelDescriptiveContentNotifRQ.xml").read
      request.env['content_type'] = 'application/xml'
      request.env['RAW_POST_DATA'] =  @body
    end
    it "should create new Hotel" do
      lambda do
        post :hotel_descriptive_content_notif
      end.should change(Hotel, :count).by(1)
    end
    it "should not create existing Hotel" do
      post :hotel_descriptive_content_notif
      lambda do
        request.env['content_type'] = 'application/xml'
        request.env['RAW_POST_DATA'] =  @body
        post :hotel_descriptive_content_notif
      end.should_not change(Hotel, :count)
    end
    it "should update existing Hotel" do
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
end
