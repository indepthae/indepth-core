ActionController::Routing::Routes.draw do |map|
  
  # transport
  map.resources :vehicles,:collection=>{:add_additional_details => [:get,:post,:put],
    :edit_additional_details => [:get,:post,:put],:select_passenger=>[:get],:list_batches_by_course=>[:get],
    :list_students_by_batch=>[:get],:check_passenger=>[:get],:list_employees_by_department=>[:get],
    :set_fare_value=>[:get],:final_list_for_vehicle=>[:get],:sort_passengers=>[:get],:passengers_list=>[:get]},
    :member=>{:assign_passengers=>:get, :delete_vehicle => :get} do |veh|
    veh.resources :vehicle_certificates, :member => {:delete_certificate => :get, :download => :get}
  end
  map.resources :routes,:collection=>{:add_additional_details => [:get,:post,:put],
    :edit_additional_details => [:get,:post,:put], :index=>[:get, :post]}, 
    :member => {:delete_route => :get, :reorder_stops => :get, :save_order => :post, 
    :route_details_csv => :get, :activate_route => :get, :inactivate_route => :get}
  map.resources :route_additional_details, :member => {:delete_details => :get, :change_field_priority => :post}
  map.resources :vehicle_additional_details, :member => {:delete_details => :get, :change_field_priority => :post}
  map.resources :vehicle_certificate_types, :member => {:delete_certificate => :get}
  map.resources :vehicle_stops, :member => {:delete_stop => :get, :activate_stop => :get, :inactivate_stop => :get}
  map.resources :vehicle_maintenances, :member => {:delete_record => :get, :download_attachment => :get}
  map.resources :transport_attendance, :collection => {:search_passengers => :post}
  map.resources :transport_employees, :member => {:remove_employee => :get}, :collection => {:show_employees => :get}
  map.resources :transport_imports, :collection => {:fetch_academic_years => :post, :update_import_form => :post}
  map.resources :transport_passenger_imports, :collection => {:download_structure => :get}, :member => {:show_import_log => :get}
  map.resources :transport_reports, :collection => {:report => :get, :fetch_report => :post, 
    :show_batches => :post, :passenger_type_search => :get, :fetch_report => :post, :show_routes => :get,
    :fetch_columns =>[:get, :post], :show_date_range => [:get], :report_csv => :get}
  map.resources :transport_gps_syncs, :collection=>{:sync_data=>:get}
  map.resources :transport_gps_settings, :member => {:delete_gps_setting => :get} 
  map.namespace(:api) do |api|
    api.resources :vehicles, :collection => {:vehicle_details => :get, :route_vehicles => :get,:student_vehicle  => :get,:employee_vehicle => :get}
    api.resources :routes,:member=> {:students_route => :get,:employees_route => :get}
    api.resources :transports, :collection => {:students => :get,:vehicle_members => :get}
  end

end
