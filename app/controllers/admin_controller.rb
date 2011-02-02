class AdminController < ApplicationController
  before_filter :admin_action, :except=>[:daily_housekeeping, :hourly_housekeeping]

  def gen_fsection
    if Fsection.first :conditions=>"budget!=0 OR balance!=0"
      flash[:notice]= "งบปัจจุบันไม่เป็นศูนย์ ไม่สามารถสร้างส่วนใหม่ได้"
    else
      Fsection.delete_all
      Fsection.create :id=>0, :code=>"00", :name=>"งบกลาง", :balance=>0, :budget=>0
      Section.all.each do |s|
        Fsection.create :id=>s.id, :code=>s.code, :name=>s.name,
          :balance=>0, :budget=>0
      end
      flash[:notice]= "สร้างส่วนสำหรับงบประมาณเรียบร้อยแล้ว"
    end
    redirect_to "/"
  end
  def update_role
    GmaUser.update $xvars[:select_user][:user_id], :role=>$xvars[:edit_role][:role]
    gma_notice "แก้ไขสิทธิเรียบร้อยแล้ว"
  end
  def update_pwd
    GmaUser.update $xvars[:select_user][:user_id], :password=>$xvars[:edit_pwd][:pwd]
    u= GmaUser.find $xvars[:select_user][:user_id]
    $xvars[:email]= u.email
    gma_notice "แก้ไขรหัสผ่านเรียบร้อยแล้ว"
  end
  def git_pull_full
    @t = "<b>git pull</b><br/>"
    @t = exec_cmd("git pull").gsub("\n","<br/>")
    @t << "<hr/>"
    @t << "<b>gems:install</b><br/>"
    @t << exec_cmd("rake gems:install").gsub("\n","<br/>")
    @t << "<hr/>"
    @t << "<b>db:migrate</b><br/>"
    @t << exec_cmd("rake db:migrate").gsub("\n","<br/>")
    @t << "<hr/>"
    @t << "<b>db:pull</b><br/>"
    h = "heroku db:pull postgres://postgres:songrit@localhost/elocal?encoding=utf8 --force --tables"
    @t << exec_cmd("#{h} gma_modules,gma_services").gsub("\n","<br/>")
    #@t << exec_cmd("#{h} cats,ptypes,plans,tasks").gsub("\n","<br/>")
    @t << exec_cmd("touch tmp/restart.txt").gsub("\n","<br/>")
    @t << "<hr/>"
  end
  def git_pull_only
    @t = "<b>git pull</b><br/>"
    @t = exec_cmd("git pull").gsub("\n","<br/>")
    update_local_server
    @t = exec_cmd("touch tmp/restart.txt").gsub("\n","<br/>")
  end
  def db_push_ms
    @t= exec_cmd('heroku db:push postgres://postgres:songrit@localhost/elocal?encoding=utf8 --force --tables gma_modules,gma_services').gsub("\n","<br/>")
  end
  def db_pull_ms
    @t= exec_cmd('heroku db:pull postgres://postgres:songrit@localhost/elocal?encoding=utf8 --force --tables gma_modules,gma_services').gsub("\n","<br/>")
  end

  def update_org
    Org.create $xvars[:edit][:org]
  end
  def users
    @users= User.paginate :page=>params[:page], :per_page=>25,
      :order=>:login
  end
  def hourly_housekeeping
    render :text => "hourly done"
  end
  def daily_housekeeping
    ActiveRecord::SessionStore::Session.destroy_all(
      ['updated_at < ?', 40.minutes.ago.utc])
    render :text => "daily done"
  end
  def destroy_gma
    GmaXmain.destroy_all
    GmaRunseq.destroy_all
    GmaDoc.destroy_all
    GmaLog.destroy_all
    GmaSearch.destroy_all
    GmaNotice.destroy_all
    LoggedException.destroy_all
    ActiveRecord::SessionStore::Session.destroy_all(
      ['updated_at < ?', 40.minutes.ago.utc])
    redirect_to "/admin/stat"
  end  

  # gma methods
  def create_news
    get_xvars
    News.create @xvars[:enter_news][:news]
    gma_notice 'news created'
  end
  
  private
  def update_local_server
    @t = exec_cmd("rake db:migrate").gsub("\n","<br/>")
#    @t = exec_cmd("heroku db:pull --tables fsections,rcats,rtypes").gsub("\n","<br/>")
  end
end
