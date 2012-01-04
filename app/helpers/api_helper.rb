module ApiHelper
  # check if avails cover from start date to end date
  def cover_stay_range(hotel,start_on,end_on, number_of_units)
    if hotel && start_on && end_on && number_of_units
      @cover = true
      start_on.upto(end_on-1) do |d|
        a = Availability.sum :booking_limit, :conditions=>['hotel_id=? AND limit_on=?',hotel.id,d]
        # a= Availability.last :conditions=>['hotel_id=? AND limit_on=?',hotel.id,d]
        unless (a >= number_of_units)
          @cover= false
          break
        end
      end
    else
      @cover = false
    end
    return @cover
  end
  def mobile?
    ['Qs2Bsh321eBEihQ','fDlmgpJuaR7mqpo'].include? @pos_id
  end
end
