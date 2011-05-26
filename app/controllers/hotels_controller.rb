class HotelsController < ApplicationController
  def index
    redirect_to :action => "hotels"
  end
  def hotels
    @hotels= Hotel.all
    @marker_image= "cat/hotel.png"
    @waypoint= @hotels.first
    @waypoint_name= @waypoint.code
  end
  def avail
    hotel_id= params[:id]
    d1= params[:d1].to_date
    d2= params[:d2].to_date
    @availabilities= Availability.all :conditions =>
      ['hotel_id=? AND limit_on>= ? AND limit_on<= ?',hotel_id,d1,d2]
    render :text => "text to render..."
  end
  def availability
    @hotel= Hotel.find params[:id]
    @avails = @hotel.avails
  end
  def create_poi
    Poi.create $xvars[:enter_poi][:poi]
    $xvars[:p][:return]= "/hotels/pois"
  end
  def pois
    @pois = Poi.all
  end
  
  # ajax
  def rr3_hotels
    @hotels= Rr1.find :all, :conditions=>['hotel_name LIKE ?', "%#{params[:term]}%"], :limit=>10
    @select= @hotels.map {|p| {:label=>"#{p.id}:#{p.hotel_name} #{p.full_address}", :value => p.hotel_name }}
    render :json=>@select
  end
end
