class SongritController < ApplicationController
  include ActionView::Helpers::DebugHelper
  include ERB::Util
  require "csv"
  require "open-uri"
  require 'nokogiri'
  require 'mechanize'

  def disp_xml
    body= File.open("public/OTA_HotelSearchRQ.xml").read
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
      :latitude => doc.xpath("//xmlns:Position").attribute("Latitude").value.to_f,
      :longitude => doc.xpath("//xmlns:Position").attribute("Longitude").value.to_f,
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

