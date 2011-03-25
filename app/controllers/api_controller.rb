class ApiController < ApplicationController
  def hotel_search
    doc = Nokogiri::XML(request.body)
    LogRequest.log(request,doc.to_s)
    # l = LogRequest.find 14
    # doc = Nokogiri::XML(l.content)
    ref_point = doc.xpath("//xmlns:RefPoint").first.text
    hotel_city_code = doc.xpath("//xmlns:HotelRef").attribute("HotelCityCode").value
    distance = doc.xpath("//xmlns:Radius").attribute("Distance").value
    distance_measure = doc.xpath("//xmlns:Radius").attribute("DistanceMeasure").value
    @criteria= doc.xpath("//xmlns:Criteria")
    @poi = Poi.find_by_name ref_point.upcase
    if @poi
      @hotels= Hotel.find :all, :origin=>@poi.ll, :within => distance 
    else
      @hotels=[]
    end
    response.content_type = "application/xml"
    render :layout => false
  end
  def hotel_descriptive_content_notif
    doc = Nokogiri::XML(request.body)
    LogRequest.log(request,doc.to_s)
    # l= LogRequest.find 7
    # doc = Nokogiri::XML(l.content)
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
    response.content_type = "application/xml"
    render :layout => false
  end
  def post
    doc = Nokogiri::XML(request.body)
    LogRequest.log(request,doc.to_s)
#    render :text => "hello, #{doc.xpath('//xmlns:HotelDescriptiveContent').attribute('HotelName').value}"
    render :layout => false 
  end
end
