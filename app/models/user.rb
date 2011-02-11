class User < GmaUser
  set_table_name :gma_users

  def gen_api_key
    GmaUser.sha1(login+Time.now.to_s)
  end
  def self.all_but_me
    find :all, :conditions=>['id!=? AND login!=?', session[:user_id], 'anonymous'], :order=>:fname
  end
  def full_name
    "#{title}#{fname} #{lname}"
  end
  def secured?
    role.upcase.split(',').include?(SECURED_ROLE)
  end
end
