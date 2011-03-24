class ApiController < ApplicationController
  def hotel_search
    doc = Nokogiri::XML(request.body)
    LogRequest.create :status=>0, :ip => request.ip, :content => doc.to_s
    # l = LogRequest.find 14
    # doc = Nokogiri::XML(l.content)
    ref_point = doc.xpath("//xmlns:RefPoint").first.text
    hotel_city_code = doc.xpath("//xmlns:HotelRef").attribute("HotelCityCode").value
    distance = doc.xpath("//xmlns:Radius").attribute("Distance").value
    distance_measure = doc.xpath("//xmlns:Radius").attribute("DistanceMeasure").value
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
    LogRequest.create :status=>0, :ip => request.ip, :content => doc.to_s
#    render :text => "hello, #{doc.xpath('//xmlns:HotelDescriptiveContent').attribute('HotelName').value}"
    render :layout => false 
  end
  def post
    doc = Nokogiri::XML(request.body)
    LogRequest.create :status=>0, :ip => request.ip, :content => doc.to_s
#    render :text => "hello, #{doc.xpath('//xmlns:HotelDescriptiveContent').attribute('HotelName').value}"
    render :layout => false 
  end
end
