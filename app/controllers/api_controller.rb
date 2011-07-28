class ApiController < ApplicationController
  # rescue_from Nokogiri::XML::XPath::SyntaxError, :with=> :render_err
  rescue_from StandardError, :with=> :render_err

  def hotel_stay_info_notif
    @doc = Nokogiri::XML(request.body)
    @log_request= LogRequest.log(request,@doc.to_s)
    @hotel_code= (@doc/'StayInfos').first[:HotelCode]
    @number_of_units= (@doc/'RoomRate').first[:NumberOfUnits].to_i
    unless Hotel.exists?(:code=>@hotel_code)
      @err= "Unable to find Hotel"
    else
      update_hotel_stay
    end
  end
  def update_hotel_stay
    @room_charges= @doc/'RevenueCategory[@RevenueCategoryCode="9"]'/'RevenueDetail'
    @rooms= []
    @exchange_rates= Nokogiri::XML(RestClient.get "http://themoneyconverter.com/THB/rss.xml")
    @rates= {:THB=>1}
    (@exchange_rates/'item').each do |e|
      unit= (e/'title').text.match(/(...)\/THB/)[1]
      rate = (e/'description').text.match(/1 Thai Baht = (.+?)\s.+/)[1]
      @rates[unit.to_sym]= rate.to_f
    end
    @room_charges.each do |charge|
      amount= charge.attribute('Amount').try(:value).try(:to_f)
      currency= charge.attribute('CurrencyCode').value
      rate= @rates[currency.to_sym] ? 1/@rates[currency.to_sym] : 0
      @rooms << {:amount=>amount,
        :currency=> currency,
        :amount_th => amount*rate, 
        :date=> charge.attribute('TransactionDate').try(:value).try(:to_date)}
    end
    @total= @rooms.inject(0) {|sum,room| sum+room[:amount_th]}
    @taxes= []
    @tax_charges= @doc/'RevenueCategory[@RevenueCategoryCode="12"]'/'RevenueDetail'
    @tax_charges.each do |charge|
      amount= charge.attribute('Amount').try(:value).try(:to_f)
      currency= charge.attribute('CurrencyCode').value
      rate= @rates[currency.to_sym] ? 1/@rates[currency.to_sym] : 0
      @taxes << {:amount=> amount,
        :currency=> currency,
        :amount_th=> amount*rate,
        :date=> charge.attribute('TransactionDate').try(:value).try(:to_date)}
    end
    @tax_total= @taxes.inject(0) {|sum,tax| sum+tax[:amount_th]}
    @hotel= Hotel.find_by_code @hotel_code
    @rooms.each do |room|
      stay = @hotel.stays.find_or_create_by_stay_on room[:date]
      stay.qty += @number_of_units
      stay.amount += room[:amount_th]
      tax= @taxes.find {|t| t[:date]= room[:date]}
      tax_amount = tax ? tax[:amount_th] : 0
      stay.tax += tax_amount
      stay.save
    end
  end
  def hotel_res
    doc = Nokogiri::XML(request.body)
    @log_request= LogRequest.log(request,doc.to_s)
    @hotel_code= doc.xpath('//xmlns:BasicPropertyInfo').attribute('HotelCode').value
    @hotel= Hotel.find_by_code @hotel_code
    @number_of_units= doc.xpath('//xmlns:RoomType').attribute('NumberOfUnits').try(:value).try(:to_i)
    @inv_code= doc.xpath('//xmlns:Inv').attribute('InvCode').value
    @start_on = doc.xpath('//xmlns:TimeSpan').attribute('Start').try(:value).try(:to_date)
    @end_on = doc.xpath('//xmlns:TimeSpan').attribute('End').try(:value).try(:to_date)
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
    # debugger
    doc = Nokogiri::XML(request.body)
    LogRequest.log(request,doc.to_s)
    # l = LogRequest.find 9
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
      @start_on= doc.xpath("//xmlns:StayDateRange").attribute("Start").try(:value).try(:to_date)
      @end_on= doc.xpath("//xmlns:StayDateRange").attribute("End").try(:value).try(:to_date)-1
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
    # debugger if code=="SONGRIT"
    hotel.update_attributes :name => doc.xpath("//xmlns:HotelDescriptiveContent").attribute("HotelName").try(:value),
      :brand_code => doc.xpath("//xmlns:HotelDescriptiveContent").attribute("BrandCode").try(:value),
      :brand_name => doc.xpath("//xmlns:HotelDescriptiveContent").attribute("BrandName").try(:value),
      :currency_code => doc.xpath("//xmlns:HotelDescriptiveContent").attribute("CurrencyCode").try(:value),
      :info_updated_on => doc.xpath("//xmlns:HotelInfo").attribute("LastUpdated").try(:value),
      :hotel_status_code => Hotel.status(doc.xpath("//xmlns:HotelInfo").attribute("HotelStatus").try(:value)),
      :lat => doc.xpath("//xmlns:Position").attribute("Latitude").try(:value),
      :lng => doc.xpath("//xmlns:Position").attribute("Longitude").try(:value),
      :address => doc.xpath("//xmlns:AddressLine").try(:text),
      :city_name => doc.xpath("//xmlns:CityName").first.try(:text),
      :postal_code => doc.xpath("//xmlns:PostalCode").try(:text),
      :state_prov => doc.xpath("//xmlns:StateProv").first.try(:text), 
      :country_name => doc.xpath("//xmlns:CountryName").first.try(:text),
      :description => doc.xpath('//xmlns:TextItem[@Title="Description"]').xpath('xmlns:Description').try(:text)
    hotel.save
    doc.xpath("//xmlns:MultimediaDescription").each do |m|
      MultimediaDescription.create :hotel_id => hotel.id, :xml => m.to_s 
    end
    contact= doc.xpath("//xmlns:ContactInfo")
    address= (contact/"Address").first
    phone= (contact/"Phone").first
    state= (address/"StateProv")
    # debugger if code=="RTPPTSOF"
    contact_info= ContactInfo.create :hotel_id => hotel.id, 
      :address=>(address/"AddressLine").try(:text),
      :city => (address/"CityName").try(:text), 
      :zip => (address/"PostalCode").try(:text),
      :country => (address/"CountryName").try(:text)
      unless state.blank?
      contact_info.update_attribute :state, state.attribute("StateCode").try(:value)
    end
    if phone
      contact_info.update_attributes :phone_location_type => phone.attribute("PhoneLocationType").try(:value).try(:to_i),
        :phone_tech_type => phone.attribute("PhoneTechType").try(:value).try(:to_i), 
        :phone_use_type => phone.attribute("PhoneUseType").try(:value).try(:to_i), 
        :area_city_code => phone.attribute("AreaCityCode").try(:value), 
        :country_access_code => phone.attribute("CountryAccessCode").try(:value), 
        :phone_number => phone.attribute("PhoneNumber").try(:value)
    end
    render_response
  end
  def hotel_avail_notif
    doc = Nokogiri::XML(request.body)
    LogRequest.log(request,doc.to_s)
    # body= File.open("public/OTA/OTA_HotelAvailNotifRQ.xml").read
    # doc = Nokogiri::XML(body)

    hotel_code = doc.xpath("//xmlns:AvailStatusMessages").attribute("HotelCode").value
    hotel= Hotel.find_by_code hotel_code
    if hotel
      doc.xpath("//xmlns:AvailStatusMessage").each do |a|
        rate_attr = a.xpath('xmlns:StatusApplicationControl').attribute('Rate')
        avail = Avail.create :hotel_id => hotel.id,
          :booking_limit => a.attribute('BookingLimit').try(:value), 
          :start_on => a.xpath('xmlns:StatusApplicationControl').attribute('Start').try(:value), 
          :end_on => a.xpath('xmlns:StatusApplicationControl').attribute('End').try(:value), 
          :rate_plan_code => a.xpath('xmlns:StatusApplicationControl').attribute('RatePlanCode').try(:value), 
          :rate => (rate_attr ? rate_attr.try(:value).try(:to_f) : 0), 
          :inv_code => a.xpath('xmlns:StatusApplicationControl').attribute('InvCode').try(:value), 
          :unique_id => a.xpath('xmlns:UniqueID').attribute('ID').try(:value), 
          :unique_id_type => a.xpath('xmlns:UniqueID').attribute('Type').value
        avail.start_on.step(avail.end_on) do |d|
          aa= Availability.first :conditions=>[
            'hotel_id=? AND inv_code=? AND limit_on=?', avail.hotel_id, avail.inv_code, d]
          if aa
            aa.update_attribute :limit, avail.booking_limit
            aa.update_attribute(:max, avail.booking_limit) if (avail.booking_limit > aa.max)
          else
            aa= Availability.create :hotel_id=> avail.hotel_id,
              :rate_plan_code => avail.rate_plan_code, 
              :rate => avail.rate, 
              :inv_code => avail.inv_code, :limit => avail.booking_limit,
              :limit_on=> d, :max=> avail.booking_limit
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
  def render_err(e)
    # debugger
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
