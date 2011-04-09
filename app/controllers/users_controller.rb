class UsersController < ApplicationController
  # gma methods
  def index
    redirect_to "/"
  end
  def update_user
    u= User.find $user_id
    u.update_attributes $xvars[:enter][:user]
    gma_notice "แก้ไขข้อมูลผู้ใช้เรียบร้อยแล้ว"
  end
  def change_password
    get_xvars
    u= User.find $user_id
    if User.authenticate u.login, @xvars[:enter][:pwd_old]
      u.password= @xvars[:enter][:pwd_new]
      u.save
      gma_notice "แก้ไขรหัสผ่านเรียบร้อยแล้ว"
    else
      gma_notice "รหัสผ่านไม่ถูกต้อง กรุณาติดต่อผู้ดูแลระบบ"
    end
  end

  # normal methods
  def user
    @u= current_user
  end
  def login
    user= GmaUser.authenticate params[:login], params[:password]
    if user
      session[:user_id]= user.id
      $user_id= user.id
      gma_log "LOGIN", "user #{user.login}(#{user.id}) logged in"
    else
      gma_log "SECURITY", "user #{params[:login]} log in failure"
      flash[:notice]= "ขออภัย รหัสไม่ถูกต้อง"
    end
    redirect_to request.referrer
  end
  def logout
#    user= GmaUser.find session[:user_id]
#    gma_log "LOGOUT", "user #{user.login}(#{user.id}) logged out"
    session[:user_id]= nil
    $user_id= anonymous.id
    session[:module] = 'public'
    redirect_to_root
  end
  def new
    @title= "Register New User"
    @user= GmaUser.new :role=>"M"
  end
  def create
    @user= GmaUser.new params[:user]
    if @user.save
      flash[:notice]= "ขึ้นทะเบียนเรียบร้อยแล้ว"
      redirect_to "/"
    else
      @user.password= ""
      flash[:notice]= "ขออภัย ไม่สามารถขึ้นทะเบียนได้"
      render :action=>:new
    end
  end

  # ajax
  def subsections
    @section= Section.find params[:id]
#    include ActionView::Helpers::FormOptionsHelper
    render :text => @template.options_from_collection_for_select(@section.subsections, :id, :name)
  end
  def check_login
    red = "#FF796C" ; green = "#B5D19D"
    if params[:login].blank?
      m = "CODE MUST NOT BE BLANK" ; c = red
    elsif User.exists?(:login=>params[:login])
      m = "CODE ALREADY EXISTS" ; c = red
    else
      m = "OK" ; c = green
    end
    t= c==green ? "<img src='/images/tick.png'>" : "<img src='/images/cross.png'>"
    render :text => "#{t} <span class='status' style='background-color:#{c}'>#{m}</span>"
  end
end