# methods included into ActiveRecord::Base
module ArMethods
  def fiscal_year(t=Time.now)
    if (10..12).include? t.month
      return t.year+544
    else
      return t.year+543
    end
  end
end