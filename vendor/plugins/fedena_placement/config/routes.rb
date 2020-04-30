ActionController::Routing::Routes.draw do |map|
  
 #placements
  map.resources :placementevents ,:collection=>{:archive=>:get},:member=>{:report=>:get} do |placementevents|
    placementevents.resources :placement_registrations ,:member=>{:approve_registration=>:get}
  end
  

end