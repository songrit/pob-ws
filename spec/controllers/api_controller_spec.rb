require 'spec_helper'

def post_request(method, xml)
  body= File.open("public/OTA/#{xml}").read
  request.env['content_type'] = 'application/xml'
  request.env['RAW_POST_DATA'] =  body
  post method
end

describe ApiController do
  integrate_views

  it "can cancel reservation (OTA_Cancel)"
  
  it "authenticate request using POS element (see Hilton pdf)"
  
  it "should rescue_from Nokogiri::XML::XPath::SyntaxError; http://www.simonecarletti.com/blog/2009/12/inside-ruby-on-rails-rescuable-and-rescue_from/" do
    post :hotel_stay_info_notif
    response.should have_tag("Error")
  end

  describe "HotelRes" do
    before do
      post_request(:hotel_descriptive_content_notif, "OTA_HotelDescriptiveContentNotifRQ.xml")
      post_request(:hotel_avail_notif, "OTA_HotelAvailNotifRQ.xml")
    end

    it "should handle HotelRes" do
      post_request :hotel_res, "OTA_HotelResRQ1.xml"
      @hotel= Hotel.find_by_code 'BOSCO'
      availability= @hotel.availabilities.last(:conditions=>['inv_code=? AND limit_on=?','STD', '2004-08-02'.to_date])
      availability.limit.should == 24      
    end
  end
  
  describe "HotelStayInfoNotifRQ" do
    before(:each) do
      post_request(:hotel_descriptive_content_notif, "OTA_HotelDescriptiveContentNotifRQ.xml")
      RestClient.should_receive(:get).at_least(:once).and_return(File.read "public/data/currency.xml")
      post_request :hotel_stay_info_notif, "OTA_HotelStayInfoNotifRQ.xml"
    end
    it "should convert tax to THB (http://themoneyconverter.com/THB/rss.xml)" do
      (1/assigns[:rates][:USD]).should be_close 30, 1
      assigns[:total].should be_close 36021, 1
      assigns[:tax_total].should be_close 5223, 1
    end
    it "should update Stay upon check-out or end of month" do
      Stay.count.should == 3
      assigns[:hotel].stays.sum(:amount).should be_close 36021, 1
      assigns[:hotel].stays.sum(:tax).should be_close 5223, 1
    end
    it "should update existing records" do
      post_request :hotel_stay_info_notif, "OTA_HotelStayInfoNotifRQ.xml"
      Stay.count.should == 3
      assigns[:hotel].stays.sum(:qty).should == 6
      assigns[:hotel].stays.sum(:amount).should be_close 36021*2, 2
      assigns[:hotel].stays.sum(:tax).should be_close 5223*2, 2
    end
  end
  
  describe "Ping" do
    it "should handle OTA_Ping" do
      post_request(:ping, "OTA_PingRQ.xml")
      @body= File.open("public/OTA/OTA_PingRQ.xml").read
      @doc = Nokogiri::XML(@body)
      echo = @doc.xpath('//xmlns:EchoData').text
      # leading and trailing space in data will be stripped
      response.should have_tag("EchoData", echo.strip) 
    end
    it "should handle invalid request" do
      post :ping
      response.should have_tag("Error")
    end
  end
  describe "HotelSearch" do
    before do
      Hotel.delete_all
      post_request(:hotel_descriptive_content_notif, "OTA_HotelDescriptiveContentNotifRQ.xml")
      post_request(:hotel_avail_notif, "OTA_HotelAvailNotifRQ.xml")
      post_request(:hotel_search, "OTA_HotelSearchRQ1.xml")
    end
    it "should search by coordinates" do
      # puts response.body
      response.should have_tag("Success")
      response.should have_tag("Property[HotelCode='BOSCO']")
    end
    it "should have availability element" do
      assigns[:start_on].should == Date.new(2004,8,2)
      assigns[:end_on].should == Date.new(2004,8,4)
      # puts response.body
      response.should have_tag("Availability")
    end      
    it "should have property description" do
      # puts response.body
      response.should have_tag("Property[Description]")
    end
  end
  
  describe "HotelRateAmountNotif" do
    it "should handle HotelRateAmountNotifRQ/RS"
  end

  describe "HotelAvailNotif" do
    before do
      post_request(:hotel_descriptive_content_notif, "OTA_HotelDescriptiveContentNotifRQ.xml")
    end
    it "should handle OTA_HotelAvailNotifRQ" do
      lambda do
        body= File.open("public/OTA/OTA_HotelAvailNotifRQ.xml").read
        request.env['content_type'] = 'application/xml'
        request.env['RAW_POST_DATA'] =  body
        post :hotel_avail_notif
      end.should change(Avail, :count)
      response.should have_tag("Success")
    end
    it "should update Availability" do
      Availability.delete_all
      body= File.open("public/OTA/OTA_HotelAvailNotifRQ.xml").read
      request.env['content_type'] = 'application/xml'
      request.env['RAW_POST_DATA'] =  body
      post :hotel_avail_notif
      Availability.all.should_not be_empty
      lambda do
        body= File.open("public/OTA/OTA_HotelAvailNotifRQ.xml").read
        request.env['content_type'] = 'application/xml'
        request.env['RAW_POST_DATA'] =  body
        post :hotel_avail_notif
      end.should_not change(Availability, :count)
    end
  end
  
  describe "HotelDescriptiveContentNotif" do
    before do
      Hotel.delete_all
      ContactInfo.delete_all
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
    it "create contact info" do
      post :hotel_descriptive_content_notif
      hotel= Hotel.last
      contact_info= hotel.contact_infos.last
      contact_info.address.should == "110 Huntington Avenue"
      contact_info.state.should == "MA"
      contact_info.country.should == "USA"
      contact_info.phone_number.should == "1-800-228-9290"
    end
    it "allow multimedia"
  end
end
