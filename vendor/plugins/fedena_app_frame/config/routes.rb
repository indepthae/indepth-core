ActionController::Routing::Routes.draw do |map|
  map.resources :app_frames, :member => {:app_frame => [:get]}
end
