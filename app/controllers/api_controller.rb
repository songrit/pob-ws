class ApiController < ApplicationController
  # unused: rescue_from Nokogiri::XML::XPath::SyntaxError, :with=> :render_err

  rescue_from StandardError, :with=> :render_err
  before_filter :validate_pos

  def validate_pos
    @doc = Nokogiri::XML(request.body)
    @log_request= LogRequest.log(request,@doc.to_s)
    decrypt_doc
    pos= YAML::load(File.open 'config/pob.yml')
    if Rails.env=='test'
      valid_pos=['test']
    else
      valid_pos= pos.each.map {|k,v| v['auth']}
    end
    requestor_id = @doc.xpath("//xmlns:RequestorID")
    if !requestor_id || requestor_id.empty?
      @err= "Unauthorized Access"
    else
      pos_id = requestor_id.attribute("ID").try(:value)
      unless valid_pos.include?(pos_id)
        @err= "Unauthorized Access"
      end
    end
    render_err if @err
    # redirect_to :action => :error if @err 
  end
  def hotel_book_id
    hotel_code= @doc.xpath("//xmlns:HotelRef").attribute("HotelCode").try(:value)
    @hotel= Hotel.find_by_code hotel_code
    @booking_id= @doc.xpath("//xmlns:Booking").attribute("ID").try(:value)
    @booking= Booking.find @booking_id
    @err= "Invalid Hotel" unless @hotel
    @err= "Invalid booking ID for this hotel" unless @hotel.id==@booking.hotel_id
    render_response
  end
  def hotel_book
    hotel_code= @doc.xpath("//xmlns:HotelRef").map {|h| h.attribute("HotelCode").try(:value)}
    @hotel= Hotel.find_by_code hotel_code
    @start_on= @doc.xpath("//xmlns:TimeSpan").attribute("Start").try(:value).try(:to_date)
    @end_on= @doc.xpath("//xmlns:TimeSpan").attribute("End").try(:value).try(:to_date)-1
    @err= "Invalid Hotel" unless @hotel
    @err= "Invalid Start Date" unless @start_on
    @err= "Invalid End Date" unless @end_on
    render_response
  end
  def hotel_avail
    hotels= @doc.xpath("//xmlns:HotelRef").map {|h| h.attribute("HotelCode").try(:value)}
    @hotels= Hotel.all :conditions=>{:code=> hotels}
    @start_on= @doc.xpath("//xmlns:StayDateRange").attribute("Start").try(:value).try(:to_date)
    @end_on= @doc.xpath("//xmlns:StayDateRange").attribute("End").try(:value).try(:to_date)-1
    # debugger
    @err= "Invalid Hotel" unless @hotels
    @err= "Invalid Start Date" unless @start_on
    @err= "Invalid End Date" unless @end_on
    render_response
  end
  def hotel_stay_info_notif
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
    @hotel_code= @doc.xpath('//xmlns:BasicPropertyInfo').attribute('HotelCode').value
    @hotel= Hotel.find_by_code @hotel_code
    @start_on = @doc.xpath('//xmlns:TimeSpan').attribute('Start').try(:value).try(:to_date)
    @reservation = @doc.xpath('//xmlns:HotelReservation')
    # @hotel.bookings.create :hotel_code => @hotel.code,
    #   :start_on => @start_on, :reservation => reservation.to_s
    @booking= Booking.create :hotel_code => @hotel.code, :hotel_id => @hotel.id, 
        :start_on => @start_on, :reservation => @reservation.to_s
    @doc.xpath('//xmlns:RoomStay').each do |stay|
      hotel_code= (stay/'BasicPropertyInfo').attribute('HotelCode').value
      hotel= Hotel.find_by_code @hotel_code
      number_of_units= (stay/'RoomType').attribute('NumberOfUnits').try(:value).try(:to_i)
      inv_code= (stay/'Inv').attribute('InvCode').value
      start_on = (stay/'TimeSpan').attribute('Start').try(:value).try(:to_date)
      end_on = (stay/'TimeSpan').attribute('End').try(:value).try(:to_date)
      # debugger
      if hotel.check_avail?(inv_code, start_on, end_on, number_of_units)
        hotel.update_avail(inv_code, start_on, end_on, number_of_units)
        reservation = @doc.xpath('//xmlns:HotelReservation')
        room_stay= RoomStay.create :booking_id => @booking.id, :hotel_id => hotel.id,
          :inv_code => inv_code, :qty => number_of_units, :start_on => start_on, 
          :end_on => end_on
        total= 0
        start_on.step(end_on-1) do |d|
          room_stay_detail= RoomStayDetail.create :room_stay_id => room_stay.id,
            :stay_on => d, :rate => hotel.rate(inv_code,d), 
            :qty => number_of_units
          total += room_stay_detail.price
        end
      else
        @err= "Your reservation cannot be booked"
      end
    end
    unless @err
      email_pattern= /^([0-9a-zA-Z]([-.\w]*[0-9a-zA-Z])*@([0-9a-zA-Z][-\w]*[0-9a-zA-Z]\.)+[a-zA-Z]{2,9})$/
      email= @doc.xpath('//xmlns:Email').text
      if email=~ email_pattern
        m= render_to_string :template => "api/hotel_res_mail_customer.haml", :layout => false
        Notifier.deliver_gma("reservation@phuketcity.com", email, "POB Hotel Reservation Notice", m )
      end
      email_hotel= @hotel.contact_infos.last.email
      m= render_to_string :template => "api/hotel_res_mail.haml", :layout => false
      if email_hotel =~ email_pattern
        Notifier.deliver_gma("reservation@phuketcity.com", email_hotel, "POB Hotel Reservation Notice", m )
      else
        Notifier.deliver_gma("reservation@phuketcity.com", "songrit@gmail.com", "POB Hotel Reservation Notice", m )
      end
    end
    render_response
  end
  def ping
    @echo_data= @doc.xpath("//xmlns:EchoData").text
    render_response
  end
  def hotel_search
    # l = LogRequest.find 9
    # @doc = Nokogiri::XML(l.content)
    @criteria= @doc.xpath("//xmlns:Criteria")
    distance = @doc.xpath("//xmlns:Radius").attribute("Distance").value
    distance_measure = @doc.xpath("//xmlns:Radius").attribute("DistanceMeasure").value
    ref_points = @doc.xpath("//xmlns:RefPoint")
    hotel_ref = @doc.xpath("//xmlns:HotelRef")
    ll= @doc.xpath('//xmlns:Position')
    unless ll.empty?
      lat= @doc.xpath('//xmlns:Position[@Latitude]').attribute('Latitude').value
      lng= @doc.xpath('//xmlns:Position[@Longitude]').attribute('Longitude').value
      @poi_coord = Geokit::LatLng.new lat,lng
    end
    select = @doc.xpath('//xmlns:Select')
    unless select.empty?
      limit= select.attribute('Limit').value
      offset= select.attribute('Offset').value
    end
    sort = @doc.xpath('//xmlns:Sort')
    unless sort.empty?
      case sort.attribute('By').value.downcase
      when 'price'
        order= 'rate_min'
      when 'rating'
        order= 'rating'
      when 'rating desc'
        order= 'rating DESC'
      else
        order= 'distance'
      end
    else
      order= 'distance'
    end
    filter = @doc.xpath('//xmlns:Filter')
    if filter.empty?
      minimum= 0
      maximum= MAX_PRICE
    else
      minimum= filter.attribute('Minimum').try(:value)|| 0
      maximum= filter.attribute('Maximum').try(:value)|| MAX_PRICE
    end
    if !ref_points.empty? # find by POI
      ref_point = ref_points.first.text
      hotel_city_code = @doc.xpath("//xmlns:HotelRef").attribute("HotelCityCode").value
      @poi = Poi.find_by_name ref_point.upcase
      if @poi
        @poi_coord= @poi.ll
        if select.empty?
          @hotels= Hotel.find :all, :origin=>@poi.ll, :within => distance, :order => order, :conditions=>['rate_min>=? and rate_min<=?',minimum,maximum]
        else
          @hotels= Hotel.find :all, :origin=>@poi.ll, :within => distance , :limit => limit, :offset => offset, :order => order, :conditions=>['rate_min>=? and rate_min<=?',minimum,maximum]
        end
      else
        @hotels=[]
      end
    elsif !hotel_ref.empty? # find by name
      order= "name" if order=="distance" # cannot use distance without origin
      hotel_name= hotel_ref.first.attribute("HotelName").try(:value)
      if hotel_name && !ll.empty?
        if select.empty?
          @hotels= Hotel.find :all, :conditions=>['lower(name) like ?', "%#{hotel_name.downcase}%"], :origin=>[lat,lng], :within=> distance, :order => order, :conditions=>['rate_min>=? and rate_min<=?',minimum,maximum]
        else
          @hotels= Hotel.find :all, :conditions=>['lower(name) like ?', "%#{hotel_name.downcase}%"], :origin=>[lat,lng], :within=> distance, :limit => limit, :offset => offset, :order => order, :conditions=>['rate_min>=? and rate_min<=?',minimum,maximum]
        end
      elsif hotel_name
        if select.empty?
          @hotels= Hotel.find :all, :conditions=>['lower(name) like ? AND rate_min>=? and rate_min<=?', "%#{hotel_name.downcase}%",minimum,maximum], :order => order
        else
          @hotels= Hotel.find :all, :conditions=>['lower(name) like ? AND rate_min>=? and rate_min<=?', "%#{hotel_name.downcase}%",minimum,maximum], :limit => limit, :offset => offset, :order => order
        end
      else
        @hotels=[]
      end
    else # find by coordinates
      # lat= @doc.xpath('//xmlns:Position[@Latitude]').attribute('Latitude').value
      # lng= @doc.xpath('//xmlns:Position[@Longitude]').attribute('Longitude').value
      # @poi_coord = Geokit::LatLng.new lat,lng
      if select.empty?
        @hotels= Hotel.find :all, :origin=>[lat,lng], :within=> distance, :order => order, :conditions=>['rate_min>=? and rate_min<=?',minimum,maximum]
      else
        @hotels= Hotel.find :all, :origin=>[lat,lng], :within=> distance, :limit => limit, :offset => offset, :order => order, :conditions=>['rate_min>=? and rate_min<=?',minimum,maximum]
      end
    end
    unless @doc.xpath("//xmlns:StayDateRange").empty?
      @start_on= @doc.xpath("//xmlns:StayDateRange").attribute("Start").try(:value).try(:to_date)
      @end_on= @doc.xpath("//xmlns:StayDateRange").attribute("End").try(:value).try(:to_date)
      units= @doc.xpath("//xmlns:StayDateRange").attribute("NumberOfUnits")
      @number_of_units= units ? units.value.to_i : 1
    end
    render_response
  end
  def hotel_descriptive_content_notif
    # l= LogRequest.find 7
    # doc = Nokogiri::XML(l.content)
    code= @doc.xpath("//xmlns:HotelDescriptiveContent").attribute("HotelCode").value
    hotel= Hotel.find_or_create_by_code(code)
    # debugger if code=="SONGRIT"
    rating= (@doc/'Award').first.try(:attribute,'Rating').try(:value).try(:to_i)||0
    hotel.update_attributes :name => @doc.xpath("//xmlns:HotelDescriptiveContent").attribute("HotelName").try(:value),
      :brand_code => @doc.xpath("//xmlns:HotelDescriptiveContent").attribute("BrandCode").try(:value),
      :brand_name => @doc.xpath("//xmlns:HotelDescriptiveContent").attribute("BrandName").try(:value),
      :currency_code => @doc.xpath("//xmlns:HotelDescriptiveContent").attribute("CurrencyCode").try(:value),
      :info_updated_on => @doc.xpath("//xmlns:HotelInfo").attribute("LastUpdated").try(:value),
      :hotel_status_code => Hotel.status(@doc.xpath("//xmlns:HotelInfo").attribute("HotelStatus").try(:value)),
      :lat => @doc.xpath("//xmlns:Position").attribute("Latitude").try(:value),
      :lng => @doc.xpath("//xmlns:Position").attribute("Longitude").try(:value),
      :address => @doc.xpath("//xmlns:AddressLine").try(:text),
      :city_name => @doc.xpath("//xmlns:CityName").first.try(:text),
      :postal_code => @doc.xpath("//xmlns:PostalCode").try(:text),
      :state_prov => @doc.xpath("//xmlns:StateProv").first.try(:text), 
      :country_name => @doc.xpath("//xmlns:CountryName").first.try(:text),
      :description => @doc.xpath('//xmlns:TextItem[@Title="Description"]').xpath('xmlns:Description').try(:text),
      :facility => @doc.xpath("//xmlns:FacilityInfo").try(:to_s),
      :doc => @doc.to_s, :rate_min=> MAX_PRICE, :rating=> rating

    hotel.save
    MultimediaDescription.delete_all :hotel_id => hotel.id
    @doc.xpath("//xmlns:MultimediaDescription").each do |m|
      MultimediaDescription.create :hotel_id => hotel.id, :xml => m.to_s 
    end
    contact= @doc.xpath("//xmlns:ContactInfo")
    address= (contact/"Address").first
    phone= (contact/"Phone").first
    state= (address/"StateProv")
    # debugger if code=="RTPPTSOF"
    contact_info= ContactInfo.create :hotel_id => hotel.id, 
      :address=>(address/"AddressLine").try(:text),
      :city => (address/"CityName").try(:text), 
      :zip => (address/"PostalCode").try(:text),
      :country => (address/"CountryName").try(:text),
      :email => (address/"Email").try(:text)
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
    # body= File.open("public/OTA/OTA_HotelAvailNotifRQ.xml").read
    # doc = Nokogiri::XML(body)
    hotel_code = @doc.xpath("//xmlns:AvailStatusMessages").attribute("HotelCode").value
    hotel= Hotel.find_by_code hotel_code
    if hotel
      @doc.xpath("//xmlns:AvailStatusMessage").each do |a|
        # debugger unless a.xpath('xmlns:StatusApplicationControl').attribute('MaxOccupancy')
        rate_attr = a.xpath('xmlns:StatusApplicationControl').attribute('Rate')
        # debugger if $rate_min
        next unless rate_attr
        # debugger if a.xpath('xmlns:UniqueID').attribute('ID').try(:value) == "7"
        rate = rate_attr.value.to_f
        hotel.update_attribute(:rate_min, rate) if (rate < hotel.rate_min)
        avail = Avail.create :hotel_id => hotel.id,
          :booking_limit => a.attribute('BookingLimit').try(:value), 
          :start_on => a.xpath('xmlns:StatusApplicationControl').attribute('Start').try(:value), 
          :end_on => a.xpath('xmlns:StatusApplicationControl').attribute('End').try(:value), 
          :rate_plan_code => a.xpath('xmlns:StatusApplicationControl').attribute('RatePlanCode').try(:value), 
          :rate => rate, 
          :inv_code => a.xpath('xmlns:StatusApplicationControl').attribute('InvCode').try(:value), 
          :unique_id => a.xpath('xmlns:UniqueID').attribute('ID').try(:value), 
          :unique_id_type => a.xpath('xmlns:UniqueID').attribute('Type').try(:value),
          :multimedias => (a/"MultimediaDescriptions").first.to_s
        # unless multimedias.empty?
        #   avail.update_attribute :multimedias, multimedias.to_s
        # end
        max= (a/"StatusApplicationControl").attribute('MaxOccupancy').try(:value).try(:to_i)
        # debugger
        avail.start_on.step(avail.end_on) do |d|
          aa= Availability.last :conditions=>[
            'hotel_id=? AND inv_code=? AND limit_on=?', avail.hotel_id, avail.inv_code, d]
          if aa
            aa.update_attributes :booking_limit=> avail.booking_limit,
              :avail_id => avail.id, 
              :rate_plan_code => avail.rate_plan_code, 
              :rate => avail.rate,
              :max=>max
            # aa.update_attribute(:max, avail.booking_limit) if (avail.booking_limit > aa.max)
          else
            aa= Availability.create :hotel_id=> avail.hotel_id,
              :avail_id => avail.id, 
              :rate_plan_code => avail.rate_plan_code, 
              :rate => avail.rate, 
              :inv_code => avail.inv_code, :booking_limit => avail.booking_limit,
              :limit_on=> d, :max=> max
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
  def render_err(e=nil)
    @err_type=1
    @err ||= e.backtrace.inspect
    render_response
  end
  def decrypt_doc
    private_key= Key.new(PRIVATE_KEY_FILE, PASSPHRASE)
    # body= File.open("public/OTA//OTA_PingRQEncrypted.xml").read
    # @doc = Nokogiri::XML(body)
    @doc.xpath("//*[@Encrypt='1']").each do |n|
      n.keys.each do |k|
        next if k=='Encrypt'
        begin
          n[k]= private_key.decrypt(n[k])
        rescue
          @err= "Invalid Encryption"
        end
      end
      begin
        n.content= private_key.decrypt(n.content) unless n.content.blank?
      rescue
        @err= "Invalid Encryption"
      end
    end
    # response.content_type = "application/xml"
    # render :text => @doc.to_s
  end
end
