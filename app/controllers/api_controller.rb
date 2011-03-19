class ApiController < ApplicationController
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
