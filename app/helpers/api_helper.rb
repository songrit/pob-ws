module ApiHelper
  # check if avails cover from start date to end date
  def cover_stay_range(avails,start_on,end_on)
    cover= true
    dates= avails.map(&:limit_on)
    start_on.upto(end_on-1) do |d|
      unless dates.include?(d)
        cover= false
        break
      end
    end
  end
end
