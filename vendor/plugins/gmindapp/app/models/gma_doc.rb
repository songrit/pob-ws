class GmaDoc < ActiveRecord::Base
  belongs_to :gma_runseq
  belongs_to :gma_service
  belongs_to :gma_user

  # secured document can be accessed if user is the person
  # who created that document
  def self.search(q, page, per_page=PER_PAGE)
    paginate :per_page=>per_page, :page => page, :conditions =>
      ["content_type=? AND data_text LIKE ? AND (secured=? OR gma_user_id=?)",
      "output", "%#{q}%", false, session[:user_id] ],
      :order=>'gma_xmain_id DESC', :select=>'DISTINCT gma_xmain_id'
  end
  def self.search_secured(q, page, per_page=PER_PAGE)
    paginate :per_page=>per_page, :page => page, :conditions =>
      ["content_type=? AND data_text LIKE ?", "output", "%#{q}%" ],
      :order=>'gma_xmain_id DESC', :select=>'DISTINCT gma_xmain_id'
  end
end
