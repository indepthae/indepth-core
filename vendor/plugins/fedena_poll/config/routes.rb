ActionController::Routing::Routes.draw do |map|
  map.resources :poll_questions,:member => { :voting => [:get, :post] }
end