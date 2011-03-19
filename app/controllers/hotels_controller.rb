class HotelsController < ApplicationController
  def booking_limit
    @avails = Avail.all
  end
  def create_poi
    Poi.create $xvars[:enter_poi][:poi]
    $xvars[:p][:return]= "/hotels/pois"
  end
  def pois
    @pois = Poi.all
  end
end
