class GmaWsQueue < ActiveRecord::Base
  named_scope :active, :conditions=>'status = 0'
end
