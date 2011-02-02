class GmaLog < ActiveRecord::Base
  serialize :params
  serialize :session

  belongs_to :gma_user
end
