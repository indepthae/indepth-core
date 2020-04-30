ActionController::Routing::Routes.draw do |map|
  map.resources :discipline_complaints,:collection=>{:search_complainee=>[:get,:post],:index=>[:get,:post],:search_juries=>[:get,:post],:search_accused=>[:get,:post],:search_users=>[:get,:post]},:member=>{:create_comment=>[:get,:post],:destroy_comment=>[:get,:post],:decision=>[:get,:post],:decision_close=>[:get,:post],:decision_remove=>[:get,:post]}
  map.resources :discipline_complaints,:member=>{:download_attachment=>[:get]}
end
