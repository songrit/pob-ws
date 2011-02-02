class AccountController < ApplicationController
  def update_user
    u= User.find $user_id
    u.update_attributes $xvars[:enter_user][:user]
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
  def index
    @u= current_user
  end
end
