require 'spec_helper'

describe ApiController do
  integrate_views

  it "can cancel reservation (OTA_Cancel)"
  
  it "should log request response and error status"

  it "should rescue_from Nokogiri::XML::XPath::SyntaxError; http://www.simonecarletti.com/blog/2009/12/inside-ruby-on-rails-rescuable-and-rescue_from/" do
    post :hotel_stay_info_notif
    response.should have_tag("Error")
  end
  it "should handle encryption" do
    post_request(:ping, "OTA_PingRQEncrypted.xml")
    # dump_response "OTA_PingRSEncrypted.xml"
    response.should have_tag("EchoData", :text => "Are you there")
  end
  it "should handle invalid encryption" do
    post_request(:ping, "OTA_PingRQEncryptedErr.xml")
    dump_response "OTA_PingRSEncryptedErr.xml"
    response.should have_tag("Error", :text => "Invalid Encryption")
  end
  it "should reject unauthorized access" do
    post_request(:ping, "OTA_PingRQnoPOS.xml")
    dump_response "OTA_PingRSnoPOS.xml"
    response.should have_tag("Error", :text => "Unauthorized Access")
  end
  describe "POB_HotelBookID" do
    before do
      Hotel.delete_all
      post_request(:hotel_descriptive_content_notif, "OTA_HotelDescriptiveContentNotifRQ.xml")
      post_request(:hotel_avail_notif, "OTA_HotelAvailNotifRQ.xml")
      post_request :hotel_res, "OTA_HotelResRQ1.xml"
      dump_response "OTA_HotelResRS1.xml"
    end
    it "should handle POB_HotelBookID" do
      booking= Booking.last
      Booking.should_receive(:find).and_return(booking)
      post_request :hotel_book_id, "POB_HotelBookIDRQ.xml"
      dump_response "POB_HotelBookIDRS.xml"
      response.should have_tag("HotelReservation")
    end
  end
  describe "POB_HotelBook" do
    before do
      Hotel.delete_all
      post_request(:hotel_descriptive_content_notif, "OTA_HotelDescriptiveContentNotifRQ.xml")
      post_request(:hotel_avail_notif, "OTA_HotelAvailNotifRQ.xml")
      post_request :hotel_res, "OTA_HotelResRQ1.xml"
    end
    it "should handle POB_HotelBook" do
      post_request :hotel_book, "POB_HotelBookRQ.xml"
      dump_response "POB_HotelBookRS.xml"
      response.should have_tag("HotelReservation")
    end
  end
  describe "POB_HotelAvail" do
    before do
      Hotel.delete_all
      post_request(:hotel_descriptive_content_notif, "OTA_HotelDescriptiveContentNotifRQ.xml")
      post_request(:hotel_avail_notif, "OTA_HotelAvailNotifRQ.xml")
    end
    it "should handle POB_HotelAvail" do
      post_request :hotel_avail, "POB_HotelAvailRQ.xml"
      # dump_response "POB_HotelAvailRS.xml"
      response.should have_tag("Availability")
      response.should have_tag("ContactInfo")
    end
  end
  describe "HotelRes" do
    before do
      post_request(:hotel_descriptive_content_notif, "OTA_HotelDescriptiveContentNotifRQ.xml")
      post_request(:hotel_avail_notif, "OTA_HotelAvailNotifRQ.xml")
      @hotel= Hotel.find_by_code 'BOSCO'
    end

    it "should create booking record" do
      Booking.delete_all
      RoomStay.delete_all
      Notifier.should_receive(:deliver_gma).exactly(2).times
      post_request :hotel_res, "OTA_HotelResRQmultiple_roomstay.xml"
      dump_response "OTA_HotelResRS.xml"
      response.should have_tag("HotelReservationID")
      Booking.count.should == 1
      RoomStay.count.should == 2
      RoomStayDetail.count.should == 4
      body = File.read('public/OTA/OTA_HotelResRQmultiple_roomstay.xml')
      @doc = Nokogiri::XML(body)
      start_on = (@doc/'TimeSpan').attribute('Start').try(:value).try(:to_date)
      availability= Availability.last(:conditions=>['inv_code=? AND limit_on=? AND hotel_id=?','STD', start_on, @hotel.id])
      availability.booking_limit.should == 33
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
    end

    it "should return Policies" do
      post_request(:hotel_avail_notif, "OTA_HotelAvailNotifRQ.xml")
      post_request(:hotel_search, "OTA_HotelSearchRQ_by_name.xml")
      dump_response "OTA_HotelSearchRS_with_policy.xml"
      response.should have_tag("Policy")
    end
    it "should return MaxOccupancy" do
      post_request(:hotel_avail_notif, "OTA_HotelAvailNotifRQ.xml")
      post_request(:hotel_search, "OTA_HotelSearchRQ_by_name.xml")
      dump_response "OTA_HotelSearchRS_by_name.xml"
      response.should have_tag("Availability[MaxOccupancy='2']")
    end
    it "should search by hotel name" do
      post_request(:hotel_avail_notif, "OTA_HotelAvailNotifRQ.xml")
      post_request(:hotel_search, "OTA_HotelSearchRQ_by_name.xml")
      dump_response "OTA_HotelSearchRS_by_name.xml"
      response.should have_tag("Success")
      response.should have_tag("Property[HotelCode='BOSCO']")
    end
    it "should search by hotel name with Position" do
      post_request(:hotel_avail_notif, "OTA_HotelAvailNotifRQ.xml")
      post_request(:hotel_search, "OTA_HotelSearchRQ_by_name_with_position.xml")
      dump_response "OTA_HotelSearchRS_by_name_with_position.xml"
      response.should have_tag("Success")
      response.should have_tag("Property[HotelCode='BOSCO']")
    end
  
    it "should search by coordinates" do
      post_request(:hotel_avail_notif, "OTA_HotelAvailNotifRQ.xml")
      post_request(:hotel_search, "OTA_HotelSearchRQ1.xml")
      response.should have_tag("Success")
      response.should have_tag("Property[HotelCode='BOSCO']")
    end
    it "should have availability element" do
      post_request(:hotel_avail_notif, "OTA_HotelAvailNotifRQ.xml")
      post_request(:hotel_search, "OTA_HotelSearchRQ1.xml")
      assigns[:start_on].should == Date.new(2004,8,2)
      assigns[:end_on].should == Date.new(2004,8,4)
      response.should have_tag("Availability")
    end      
    it "should have property description" do
      post_request(:hotel_avail_notif, "OTA_HotelAvailNotifRQ.xml")
      post_request(:hotel_search, "OTA_HotelSearchRQ1.xml")
      response.should have_tag("Property[Description]")
    end
    it "should have MultimediaDescription" do
      post_request(:hotel_avail_notif, "OTA_HotelAvailNotifRQ.xml")
      post_request(:hotel_search, "OTA_HotelSearchRQ1.xml")
      response.should have_tag("MultimediaDescription")
    end
    it "returns Multimedia for Availability" do
      post_request(:hotel_avail_notif, "OTA_HotelAvailNotifRQ7.xml")
      post_request(:hotel_search, "OTA_HotelSearchRQ1.xml")
      response.body.should include_text("Renovation Area Completion Date 1")
    end
    it "returns FacilityInfo" do
      post_request(:hotel_avail_notif, "OTA_HotelAvailNotifRQ7.xml")
      post_request(:hotel_search, "OTA_HotelSearchRQ1.xml")
      dump_response "dump.xml"
      response.body.should have_tag("FacilityInfo")
    end
    it "can select limit, offset when search by lat, long" do
      post_request(:hotel_avail_notif, "OTA_HotelAvailNotifRQ7.xml")
      post_request(:hotel_search, "OTA_HotelSearchRQ1.xml")
      dump_response "OTA_HotelSearchRS1.xml"
      response.body.should have_tag("Property")
      post_request(:hotel_search, "OTA_HotelSearchRQ3.xml") # limit=0
      dump_response "OTA_HotelSearchRS3.xml"
      response.body.should_not have_tag("Property")
    end
    it "should not return unavailable hotels" do
      post_request(:hotel_search, "OTA_HotelSearchRQ1.xml")
      response.body.should_not have_tag("Property")
      post_request(:hotel_avail_notif, "OTA_HotelAvailNotifRQ7.xml")
      post_request(:hotel_search, "OTA_HotelSearchRQ1.xml")
      dump_response "OTA_HotelSearchRS1.xml"
      response.body.should have_tag("Property")
      a= Availability.first :conditions=>{:limit_on=>"2004-08-02"}
      a.booking_limit= 0
      a.save
      # Availability.all.each {|a| a.limit=0; a.save}
      post_request(:hotel_search, "OTA_HotelSearchRQ1.xml")
      dump_response "OTA_HotelSearchRS1.xml"
      response.body.should_not have_tag("Property")
    end
    it "should return Property when not specify StayDateRange" do
      post_request(:hotel_search, "OTA_HotelSearchRQ4.xml")
      dump_response "OTA_HotelSearchRS4.xml"
      response.body.should have_tag("Property")
    end
    it "should not return partially available hotels" do
      # 2004-08-02 to 2004-08-05
      post_request(:hotel_avail_notif, "OTA_HotelAvailNotifRQ7.xml")
      # 2004-08-02 to 2004-08-10
      post_request(:hotel_search, "OTA_HotelSearchRQ5.xml")
      dump_response "OTA_HotelSearchRS5.xml"
      response.body.should_not have_tag("Property")
    end
  end
  
  describe "HotelAvailNotif" do
    before do
      post_request(:hotel_descriptive_content_notif, "OTA_HotelDescriptiveContentNotifRQ.xml")
    end
    it "should update Hotel#rate_min" do
      h= Hotel.last
      h.rate_min.should == MAX_PRICE
      $rate_min= true
      post_request(:hotel_avail_notif, "OTA_HotelAvailNotifRQ.xml")
      $rate_min= nil
      h= Hotel.last
      h.rate_min.should == 500
    end
    it "should handle MaxOccupancy" do
      post_request(:hotel_avail_notif, "OTA_HotelAvailNotifRQ.xml")
      a= Availability.first
      a.max.should == 2
    end
    it "keep Multimedia from HotelAvail" do
      post_request(:hotel_avail_notif, "OTA_HotelAvailNotifRQ7.xml")
      dump_response("OTA_HotelAvailNotifRS7.xml")
      a= Availability.first
      a.avail.multimedias.should include_text("Renovation Area Completion Date 1")
    end
    it "should handle OTA_HotelAvailNotifRQ" do
      lambda do
        post_request(:hotel_avail_notif, "OTA_HotelAvailNotifRQ.xml")
      end.should change(Avail, :count)
      response.should have_tag("Success")
    end
    it "should update Availability" do
      Availability.delete_all
      post_request(:hotel_avail_notif, "OTA_HotelAvailNotifRQ.xml")
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
      MultimediaDescription.delete_all
      @body= File.open("public/OTA/OTA_HotelDescriptiveContentNotifRQ.xml").read
      request.env['content_type'] = 'application/xml'
      request.env['RAW_POST_DATA'] =  @body
    end
    it "should update rating" do
      post_request :hotel_descriptive_content_notif, "OTA_HotelDescriptiveContentNotifRQ.xml"
      Hotel.last.rating.should == 3
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
        post_request :hotel_descriptive_content_notif, "OTA_HotelDescriptiveContentNotifRQ1.xml"
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
      post_request :hotel_descriptive_content_notif, "OTA_HotelDescriptiveContentNotifRQ3.xml"
      hotel= Hotel.find_by_code("RTPPTSOF")
      contact_info= hotel.contact_infos.last
      contact_info.address.should == "BP 60008FAA'A TAHITI"
      contact_info.country.should == "FRENCH POLYNESIA"
      contact_info.phone_number.should == "689/866600"
    end
    it "handle MultimediaDescription" do
      post_request :hotel_descriptive_content_notif, "OTA_HotelDescriptiveContentNotifRQ3.xml"
      MultimediaDescription.count.should == 11
    end
    it "keep all digits for lat, lng" do
      post_request :hotel_descriptive_content_notif, "OTA_HotelDescriptiveContentNotifRQ4.xml"
      dump_response "OTA_HotelDescriptiveContentNotifRS4.xml"
      hotel= Hotel.find_by_code("SONGRIT")
      hotel.lat.should == 7.771828058680014
      hotel.lng.should == 98.3205502599717
    end
    it "should keep FacilityInfo" do
      post_request :hotel_descriptive_content_notif, "OTA_HotelDescriptiveContentNotifRQ.xml"
      hotel= Hotel.find_by_code("BOSCO")
      hotel.facility.should have_tag("FacilityInfo")
    end
    it "should update MultimediaDescription instead of append" do
      post_request :hotel_descriptive_content_notif, "OTA_HotelDescriptiveContentNotifRQ.xml"
      lambda do
        post_request :hotel_descriptive_content_notif, "OTA_HotelDescriptiveContentNotifRQ.xml"
      end.should_not change(MultimediaDescription, :count)
    end
  end
end
