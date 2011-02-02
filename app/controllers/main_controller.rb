class MainController < ApplicationController
  require "open-uri"
  require "hpricot"

  def status
    @xmain= GmaXmain.find params[:id]
    @xvars= @xmain.xvars
#    flash.now[:notice]= "รายการ #{@xmain.id} ได้ถูกยกเลิกแล้ว" if @xmain.status=='X'
    flash.now[:notice]= "transaction #{@xmain.id} was cancelled" if @xmain.status=='X'
  rescue
    flash[:notice]= "could not find transaction id <b> #{params[:id]} </b>"
    redirect_to_root
  end
  def help
#    render :text => "help"
  end
  def index
    @news = News.all :limit => 5, :order => "created_at DESC"
    @xmains= GmaXmain.all :conditions=>"status='R' or status='I' ", :order=>"created_at", :include=>:gma_runseqs
  end
  def search
    if params[:q]
      @q = params[:q]
      do_search
    elsif params[:gma_search]
      @q = params[:gma_search][:q]
      s= GmaSearch.new params[:gma_search]
      s.ip= request.env["REMOTE_ADDR"]
      s.save
      do_search
    else
      redirect_to "/"
    end
  end
  def do_search
    if current_user.secured?
      @docs = GmaDoc.search_secured(@q.downcase, params[:page], PER_PAGE)
    else
      @docs = GmaDoc.search(@q.downcase, params[:page], PER_PAGE)
    end
    @xmains = GmaXmain.find @docs.map(&:gma_xmain_id)
  end
  def err404
    gma_log 'ERROR', 'main/err404'
    flash[:notice] = "We're sorry, but something went wrong. We've been notified about this issue and we'll take a look at it shortly."
    redirect_to '/'
  end
  def err500
    gma_log 'ERROR', 'main/err500'
    flash[:notice] = "We're sorry, but something went wrong. We've been notified about this issue and we'll take a look at it shortly."
    redirect_to '/'
  end

  # ajax call to update modules menu and sidebar
  def modules
    @modules= GmaModule.all :order=>"seq"
    render :layout => false
  end
  def sidebar
    @gma_module= GmaModule.find_by_name params[:module]
    @waypoint= Waypoint.find session[:waypoint_id]
    render :layout => false
  end
end
