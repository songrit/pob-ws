class GmaNotice < ActiveRecord::Base
  named_scope :new_notices, :conditions=>{:unread=>true}
end
