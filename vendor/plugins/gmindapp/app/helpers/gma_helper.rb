module GmaHelper
  def log_type(l)
    case l
    when "ERROR"
      "logout.png"
    when "SECURITY"
      "lock_delete.png"
    end
  end
end
