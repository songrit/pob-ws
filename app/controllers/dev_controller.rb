class DevController < ApplicationController
  def index
    redirect_to "/gma/view_mm"
  end
  def set_session
    session[:aa]= "aa"
    redirect_to :action => "test_session"
  end
  def test_session
    render :text => session[:aa]
  end
end
