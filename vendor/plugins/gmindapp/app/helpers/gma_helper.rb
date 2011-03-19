module GmaHelper
  def log_type(l)
    case l
    when "ERROR"
      "logout.png"
    when "SECURITY"
      "lock_delete.png"
    when "LOGIN"
      "lock_delete.png"
    else
      "cross.png"
    end
  end
end
