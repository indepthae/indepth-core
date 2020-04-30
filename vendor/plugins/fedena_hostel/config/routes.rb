ActionController::Routing::Routes.draw do |map|
  
  #hostel
  map.resources :hostels,:collection=>{:hostel_dashboard=>:get,:add_additional_details => [:get,:post,:put],:edit_additional_details => [:get,:post,:put],:room_availability_details=>[:get],:room_availability_details_csv=>[:get],:individual_room_details=>[:get]} do |hostel|
    hostel.resources :wardens
  end
  map.resources :room_details,:collection=>{:add_additional_details => [:get,:post,:put],:edit_additional_details => [:get,:post,:put]}
#  map.resources :hostel_fee,:collection=>{:hostel_fees_report_csv => [:get]}

  map.namespace(:api) do |api|
    api.resources :hostels
  end
  
end