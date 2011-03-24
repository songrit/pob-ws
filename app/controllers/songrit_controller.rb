class SongritController < ApplicationController
  include ActionView::Helpers::DebugHelper
  include ERB::Util
  require "csv"
  require "open-uri"
  require 'nokogiri'
  # require 'geokit'

  def test_api
    body= File.open("public/OTA/OTA_HotelSearchRQ.xml").read
    f= RestClient.post "http://pob-ws.heroku.com/api/hotel_search", body
    render :xml => f.body
  end
  def process_hotel_search
    l = LogRequest.find 14
    doc = Nokogiri::XML(l.content)
    ref_point = doc.xpath("//xmlns:RefPoint").first.text
    hotel_city_code = doc.xpath("//xmlns:HotelRef").attribute("HotelCityCode").value
    distance = doc.xpath("//xmlns:Radius").attribute("Distance").value
    distance_measure = doc.xpath("//xmlns:Radius").attribute("DistanceMeasure").value
    poi = Poi.find_by_name ref_point.upcase
    if poi
      @hotels= Hotel.find :all, :origin=>[poi.lat,poi.lng], :within => distance 
    else
      @hotels=[]
    end
    render :layout => true,:text=>@hotels.inspect
  end
  
  # Utilities, used in User module
  def disp_xml_rq
    body= File.open("public/OTA/OTA_HotelSearchRQ.xml").read
    render :xml => body
  end
  def disp_xml_rs
    body= File.open("public/OTA/OTA_HotelSearchRS.xml").read
    render :xml => body
  end
  def get_avail
    l = LogRequest.find 11
    doc = Nokogiri::XML(l.content)
    hotel_code = doc.xpath("//xmlns:AvailStatusMessages").attribute("HotelCode").value
    hotel_id= 3
    t = ""
    doc.xpath("//xmlns:AvailStatusMessage").each do |a|
      avail = Avail.create :hotel_id => hotel_id,
        :booking_limit => a.attribute('BookingLimit').value, 
        :start_on => a.xpath('xmlns:StatusApplicationControl').attribute('Start').value, 
        :end_on => a.xpath('xmlns:StatusApplicationControl').attribute('End').value, 
        :rate_plan_code => a.xpath('xmlns:StatusApplicationControl').attribute('RatePlanCode').value, 
        :inv_code => a.xpath('xmlns:StatusApplicationControl').attribute('InvCode').value, 
        :unique_id => a.xpath('xmlns:UniqueID').attribute('ID').value, 
        :unique_id_type => a.xpath('xmlns:UniqueID').attribute('Type').value
      t << "bl = #{a.attribute('BookingLimit').value}<br/>"
    end
    render :text => t, :layout => true 
  end
  def get_hotel
    l= LogRequest.find 7
    doc = Nokogiri::XML(l.content)
    hotel= Hotel.new :code=> doc.xpath("//xmlns:HotelDescriptiveContent").attribute("HotelCode").value,
      :name => doc.xpath("//xmlns:HotelDescriptiveContent").attribute("HotelName").value,
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
    render :layout => "application", :text => "hello, #{doc.xpath('//xmlns:HotelDescriptiveContent').attribute('HotelName').value}"
  end
  def show_hotel
    @hotel= Hotel.last
  end
  def test_ip
    render :text => request.ip
  end
  def test_escape
    render :text => html_escape("<aa>")
  end
  def end_of_last_month
    d= Date.today
    dd= Date.new d.year, d.month, 1
    render :text=> dd-1
  end
  def send_dloc_mail
    count= 0
    DlocMail.unsent.each do |m|
      from= "dlocthai@gmail.com"
      #    if m.recipient =~ /^([0-9a-zA-Z]([-.\w]*[0-9a-zA-Z])*@([0-9a-zA-Z][-\w]*[0-9a-zA-Z]\.)+[a-zA-Z]{2,9})$/
      Notifier.deliver_gma(from, m.recipient.chomp(","), m.subject, m.body||="" )
      #    end
      m.sent= true
      m.save
      count += 1
    end
    logger.info "#{Time.now}: sent #{count} mails\n\n"
    render :text => "#{Time.now}: sent #{count} mails\n\n"
  end
  def test_user_agent
    render :text => request.user_agent
  end
  def test_rmagick
    img_orig = Magick::Image.read("tmp/f6").first
#    img = img_orig.matte_floodfill("white")
    img_orig.write("tmp/f0.gif")
    render :text => "done"
  end
  def test_postimg
    p = postimg("/media/DATA/pictures/2print/IMAG0742.jpg")
    render :text => "<a href='#{p}'>#{p}</a>"
  end
end

