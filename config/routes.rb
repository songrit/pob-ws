ActionController::Routing::Routes.draw do |map|
  map.connect 'feed', :controller => "main", :action => "feed", :format => "rss"
  map.root :controller => "main"
  # See how all your routes lay out with "rake routes"
  map.connect ':controller/:action/:id.:format'
end
