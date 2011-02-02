require "gma"

class ActionController::Base
  include Gma
  include ExceptionLoggable
  around_filter :make_session_available_in_model

  protected

  def make_session_available_in_model
    klasses = [ActiveRecord::Base, ActiveRecord::Base.class]
    # request is conflict with exception logger plugin
    methods = ["session", "cookies", "params"]
#    methods = ["session", "cookies", "params", "request"]

    methods.each do |shenanigan|
      oops = instance_variable_get(:"@_#{shenanigan}")

      klasses.each do |klass|
        klass.send(:define_method, shenanigan, proc { oops })
      end
    end

    yield

    methods.each do |shenanigan|
      klasses.each do |klass|
        klass.send :remove_method, shenanigan
      end
    end

  end

end

class ActiveRecord::Base
  include Gma
  def session
    instance_variable_get(:"@_session")
  end
  def before_save
    if self.respond_to?("gma_user_id")
      unless gma_user_id
        if session && session[:user_id]
#          user = GmaUser.find(session[:user_id])
          user_id = session[:user_id]
        else
          anonymous = GmaUser.find_by_login("anonymous")
          user_id = anonymous.id if anonymous
        end
        self.gma_user_id= user_id if user_id
      end
    end
  end
end

class ActionView::Base
  include Gma
  require 'linguistics'
  Linguistics::use( :en )
  Float.extend Linguistics
end
