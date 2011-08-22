module ApiHelper
  # check if avails cover from start date to end date
  def cover_stay_range(hotel,start_on,end_on)
    cover= true
    start_on.upto(end_on-1) do |d|
      a= Availability.last :conditions=>['hotel_id=? AND limit_on=?',hotel.id,d]
      unless (a && a.limit>0)
        cover= false
        break
      end
    end
  end
end
