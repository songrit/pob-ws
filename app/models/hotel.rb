class Hotel < ActiveRecord::Base
  def self.status(s)
    case s.downcase
    when "open"
      1
    else
      0
    end
  end
end
