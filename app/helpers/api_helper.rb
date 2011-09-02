module ApiHelper
  # check if avails cover from start date to end date
  def cover_stay_range(hotel,start_on,end_on, number_of_units)
    @cover= true
    start_on.upto(end_on-1) do |d|
      a= Availability.last :conditions=>['hotel_id=? AND limit_on=?',hotel.id,d]
      unless (a && a.booking_limit>=number_of_units)
        @cover= false
        break
      end
    end
    return @cover
  end
end
