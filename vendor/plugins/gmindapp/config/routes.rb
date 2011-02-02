ActionController::Routing::Routes.draw do |map|
  map.connect "/e/:action/:id", :controller => "logged_exceptions"
  map.connect '/run/:module/:service/:id', :controller=>'engine', :action=>'init'
end
