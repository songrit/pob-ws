class GmaUser < ActiveRecord::Base
  has_many :gma_xmains
  has_many :gma_logs
  has_many :gma_docs
  validates_uniqueness_of :login

  def self.authenticate(login,password)
    find_by_login_and_password login, GmaUser.sha1(password)
  end
  def password=(pwd)
    write_attribute "password", GmaUser.sha1(pwd)
  end
  def full_name
    "#{title}#{fname} #{lname}"
  end

  protected
  def self.sha1(s)
    Digest::SHA1.hexdigest(s)
  end
end
