module HotelsHelper
  def disp_markers
    js = ""
    @hotels.each_with_index do |h,i|
      js << "latLng = new google.maps.LatLng(#{h.lat}, #{h.lng});"
      js << "latlngbounds.extend( latLng );"
      js << "  var marker_#{i} = new google.maps.Marker({"
      js << "  position: latLng,"
      js << "  title: '#{h.name}',"
      js << "  map: map,"
      js << "  icon: '/images/#{@marker_image}'"
      js << "});"
      # js << "google.maps.event.addListener(marker_#{i}, 'click', function() {"
      # js << "  window.location = '/hotels/availability/#{h.id}';"
      # js << "  window.location = '/songrit/cal';"
      # js << "});"
    end
    js << ""
  end
end
