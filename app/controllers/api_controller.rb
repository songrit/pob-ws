class ApiController < ApplicationController
  rescue_from Nokogiri::XML::XPath::SyntaxError, :with=> :render_err

  def hotel_res
    doc = Nokogiri::XML(request.body)
    @log_request= LogRequest.log(request,doc.to_s)
    @hotel_code= doc.xpath('//xmlns:BasicPropertyInfo').attribute('HotelCode').value
    @hotel= Hotel.find_by_code @hotel_code
    @number_of_units= doc.xpath('//xmlns:RoomType').attribute('NumberOfUnits').value.to_i
    @inv_code= doc.xpath('//xmlns:Inv').attribute('InvCode').value
    @start_on = doc.xpath('//xmlns:TimeSpan').attribute('Start').value.to_date
    @end_on = doc.xpath('//xmlns:TimeSpan').attribute('End').value.to_date
    if check_avail?
      update_avail
    else
      @err= "Your reservation cannot be booked"
    end
    render_response
  end
  def ping
    doc = Nokogiri::XML(request.body)
    LogRequest.log(request,doc.to_s)
    @echo_data= doc.xpath("//xmlns:EchoData").text
    render_response
  end
  def hotel_search
    doc = Nokogiri::XML(request.body)
    LogRequest.log(request,doc.to_s)
    # l = LogRequest.find 14
    # doc = Nokogiri::XML(l.content)
    @criteria= doc.xpath("//xmlns:Criteria")
    distance = doc.xpath("//xmlns:Radius").attribute("Distance").value
    distance_measure = doc.xpath("//xmlns:Radius").attribute("DistanceMeasure").value
    ref_points = doc.xpath("//xmlns:RefPoint")
    unless ref_points.empty?
      ref_point = ref_points.first.text
      hotel_city_code = doc.xpath("//xmlns:HotelRef").attribute("HotelCityCode").value
      @poi = Poi.find_by_name ref_point.upcase
      if @poi
        @poi_coord= @poi.ll
        @hotels= Hotel.find :all, :origin=>@poi.ll, :within => distance 
      else
        @hotels=[]
      end
    else # find by coordinates
      lat= doc.xpath('//xmlns:Position[@Latitude]').attribute('Latitude').value
      lng= doc.xpath('//xmlns:Position[@Longitude]').attribute('Longitude').value
      @poi_coord = Geokit::LatLng.new lat,lng
      @hotels= Hotel.find :all, :origin=>[lat,lng], :within=> distance
    end
    unless doc.xpath("//xmlns:StayDateRange").empty?
      @start_on= doc.xpath("//xmlns:StayDateRange").attribute("Start").value.to_date
      @end_on= doc.xpath("//xmlns:StayDateRange").attribute("End").value.to_date
    end
    render_response
  end
  def hotel_descriptive_content_notif
    doc = Nokogiri::XML(request.body)
    LogRequest.log(request,doc.to_s)
    # l= LogRequest.find 7
    # doc = Nokogiri::XML(l.content)
    code= doc.xpath("//xmlns:HotelDescriptiveContent").attribute("HotelCode").value
    hotel= Hotel.find_or_create_by_code(code)
    hotel.update_attributes :name => doc.xpath("//xmlns:HotelDescriptiveContent").attribute("HotelName").value,
      :brand_code => doc.xpath("//xmlns:HotelDescriptiveContent").attribute("BrandCode").value,
      :brand_name => doc.xpath("//xmlns:HotelDescriptiveContent").attribute("BrandName").value,
      :currency_code => doc.xpath("//xmlns:HotelDescriptiveContent").attribute("CurrencyCode").value,
      :info_updated_on => doc.xpath("//xmlns:HotelInfo").attribute("LastUpdated").value,
      :hotel_status_code => Hotel.status(doc.xpath("//xmlns:HotelInfo").attribute("HotelStatus").value),
      :lat => doc.xpath("//xmlns:Position").attribute("Latitude").value.to_f,
      :lng => doc.xpath("//xmlns:Position").attribute("Longitude").value.to_f,
      :address => doc.xpath("//xmlns:AddressLine").text,
      :city_name => doc.xpath("//xmlns:CityName").first.text,
      :postal_code => doc.xpath("//xmlns:PostalCode").text,
      :state_prov => doc.xpath("//xmlns:StateProv").first.text, 
      :country_name => doc.xpath("//xmlns:CountryName").first.text,
      :description => doc.xpath('//xmlns:TextItem[@Title="Description"]').xpath('xmlns:Description').text
    hotel.save
    render_response
  end
  def hotel_avail_notif
    # doc = Nokogiri::XML(request.body)
    # LogRequest.log(request,doc.to_s)
    body= File.open("public/OTA/OTA_HotelAvailNotifRQ.xml").read
    doc = Nokogiri::XML(body)

    hotel_code = doc.xpath("//xmlns:AvailStatusMessages").attribute("HotelCode").value
    hotel= Hotel.find_by_code hotel_code
    if hotel
      doc.xpath("//xmlns:AvailStatusMessage").each do |a|
        avail = Avail.create :hotel_id => hotel.id,
          :booking_limit => a.attribute('BookingLimit').value, 
          :start_on => a.xpath('xmlns:StatusApplicationControl').attribute('Start').value, 
          :end_on => a.xpath('xmlns:StatusApplicationControl').attribute('End').value, 
          :rate_plan_code => a.xpath('xmlns:StatusApplicationControl').attribute('RatePlanCode').value, 
          :inv_code => a.xpath('xmlns:StatusApplicationControl').attribute('InvCode').value, 
          :unique_id => a.xpath('xmlns:UniqueID').attribute('ID').value, 
          :unique_id_type => a.xpath('xmlns:UniqueID').attribute('Type').value
        avail.start_on.step(avail.end_on) do |d|
          aa= Availability.first :conditions=>[
            'hotel_id=? AND inv_code=? AND limit_on=?', avail.hotel_id, avail.inv_code, d]
          if aa
            aa.update_attribute :limit, avail.booking_limit
          else
            aa= Availability.create :hotel_id=> avail.hotel_id,
              :rate_plan_code => avail.rate_plan_code, 
              :inv_code => avail.inv_code, :limit => avail.booking_limit, :limit_on=> d
          end
        end
      end
    else
      @err= "Hotel code does not exists"
    end
    render_response
  end
  
  private
  def render_response
    response.content_type = "application/xml"
    render :layout => false
  end
  def render_err
    @err_type=1
    @err ||= "Unknown"
    render_response
  end
  def update_avail
    @start_on.step(@end_on) do |d|
      availability= @hotel.availabilities.last(:conditions=>['inv_code=? AND limit_on=?',@inv_code, d])
      availability.limit -= @number_of_units
      availability.save
    end
  end
  def check_avail?
    avail= true
    @start_on.step(@end_on) do |d|
      # debugger
      availability= @hotel.availabilities.last(:conditions=>['inv_code=? AND limit_on=?',@inv_code, d])
      if availability
        avail= false if (availability.limit < @number_of_units)
      else
        avail= false
      end
    end
    avail
  end
end
