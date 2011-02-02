class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  helper_method :fiscal_year, :finance_office?, :office_office?,
    :own_xmain?, :mobile_device?, :atype, :b, :end_of_last_month,
    :begin_of_last_month, :begin_of_fiscal_year

  # protect_from_forgery # See ActionController::RequestForgeryProtection for details
  #
  # geocode_ip_address

  # Scrub sensitive parameters from your log
  # filter_parameter_logging :password

  def finance_office?
    current_user.role && current_user.role.upcase.split(',').include?('CO') && current_user.section_id==2
  end
  def office_office?
    current_user.role && current_user.role.upcase.split(',').include?('CO') && current_user.section_id==1
  end
#----------------------
  def atype(a)
    ACCOUNT_TYPE[a-1]
  end
  def end_of_last_month
    d= Date.today
    dd= Date.new d.year, d.month, 1
    dd-1
  end
  def begin_of_last_month
    d= Date.today
    if d.month==1
      m = 12
      y = d.year-1
    else
      m = d.month-1
      y = d.year
    end
    dd= Date.new y, m, 1
  end
  def begin_of_fiscal_year
    d= Date.today
    year = d.month<10 ? d.year-1 : d.year
    dd= Date.new year, 10, 1
  end
  def b(s)
    "<b>#{s}</b>"
  end
  def login_laas
    ff=FireWatir::Firefox.new :waitTime=>4
    ff.goto('http://www.laas.go.th/')
    ff.text_field(:id,"_ctl0_txtUserName").set(LAAS_USER)
    ff.text_field(:id,"_ctl0_txtPassword").set(LAAS_PASSWORD)
    ff.button(:name,"_ctl0:btnLogin").click
    ff
  end
  def own_xmain?
    if $xvars
      return current_user.id==$xvars[:user_id]
    else
      return true
    end
  end
  def fiscal_year(t=Time.now)
    if (10..12).include? t.month
      return t.year+544
    else
      return t.year+543
    end
  end
  
  def mobile_device?
    request.user_agent =~ /Mobile|webOS/
  end


end
