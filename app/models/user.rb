class User < GmaUser
  set_table_name :gma_users
  belongs_to :section
  belongs_to :subsection
  has_many :car_requests, :foreign_key=>"gma_user_id", :order=>"schedule_at"

  named_scope :finance, :conditions=>{:section_id=>FINANCE_SECTION}, :order=>:fname

  def self.mayor
    find MAYOR
  end
  def self.finance_head
    find FINANCE_HEAD
  end
  def self.palat
    find PALAD
  end
  def self.palad
    find PALAD
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
