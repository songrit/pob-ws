class UsersController < ApplicationController
#  require "Gma"
#  include GmaMethods
  def login
    user= GmaUser.authenticate params[:login], params[:password]
    if user
      session[:user_id]= user.id
      $user_id= user.id
      Gma_log "LOGIN", "user #{user.login}(#{user.id}) logged in"
    else
      Gma_log "SECURITY", "user #{params[:login]} log in failure"
      flash[:notice]= "Incorrect username and password credential"
    end
    redirect_to_root
  end
  def logout
    user= GmaUser.find session[:user_id]
    Gma_log "LOGOUT", "user #{user.login}(#{user.id}) logged out"
    reset_session
    redirect_to_root
  end
  def new
    @title= "Register New User"
    @user= GmaUser.new
  end
  def create
    @user= GmaUser.new params[:user]
    if @user.save
      flash[:notice]= "Register complete, please login"
      redirect_to "/"
    else
      flash[:notice]= "Sorry, something is wrong, please make sure your login is unique"
      render :action=>:new
    end
  end
end