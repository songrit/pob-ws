class LogRequest < ActiveRecord::Base
  def self.log(request,s)
    create :status=>0, :ip => request.ip, :content => s,
      :request_uri => request.request_uri
  end
end
