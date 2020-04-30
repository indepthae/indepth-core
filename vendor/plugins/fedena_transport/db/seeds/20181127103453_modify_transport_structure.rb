FeatureLock.run_with_feature_lock :transport do
  log = Logger.new("log/transport_data.log")
  log.debug("=====================================================================")
  log.debug("Updating routes and vehicles" + Time.now.to_s)
  schools = School.all(:joins => "INNER JOIN routes ON schools.id = routes.school_id", :group => "id")
  schools.each do |school|
    log.debug("School: #{school.id}")
    MultiSchool.current_school = school
    vehicles = Vehicle.all
    main_routes = Route.all(:select=>"distinct(main_route_id) as id", :conditions=>"main_route_id is not null") 
    main_routes += Route.all( :select => "id", :conditions => "main_route_id is null")
    main_route_ids = main_routes.collect(&:id).uniq
    all_main_routes = Route.find_all_by_id(main_route_ids)
    routes = Route.all
    delete_routes = (routes - all_main_routes)
    academic_year_id = AcademicYear.active.first.id if AcademicYear.active.present?
    all_routes = {}
    all_stops = {}
    all_main_routes.each do |r|
      all_routes[r.id] = {:name => r.name, :fare => r.fare.to_f, :stops => []}
    end
    routes.each do |r|
      stop = VehicleStop.new(:academic_year_id => academic_year_id, :name => r.name)
      stop.send(:create_without_callbacks)
      all_stops[r.id] = stop.id
      if main_route_ids.include? r.id
        all_routes[r.id][:stops] << {:name => r.name, :fare => r.fare.to_f, :stop_id => stop.id} if all_routes[r.id].present?
        all_routes[r.main_route_id][:stops] << {:name => r.name, :fare => r.fare.to_f, :stop_id => stop.id} if r.main_route_id.present? and !(r.id == r.main_route_id) and all_routes[r.main_route_id].present?
      else
        all_routes[r.main_route_id][:stops] << {:name => r.name, :fare => r.fare.to_f, :stop_id => stop.id} if all_routes[r.main_route_id].present?
      end
    end
    log.debug("Vehicle stops created")
    vehicles.each do |v|
      if academic_year_id.present?
        v.academic_year_id = academic_year_id
        v.send(:update_without_callbacks)
      end
      if all_routes[v.main_route_id].present?
        (all_routes[v.main_route_id][:vehicle_id] ||= []) << v.id
      end
    end
    log.debug("Vehicles updated")
    all_routes.each do |id, values|
      old_route = Route.find(id)
      values[:vehicle_id] = [nil] if values[:vehicle_id].nil?
      values[:vehicle_id].each_with_index do |vehicle_id, i|
        route = if i == 0
          old_route.attributes = {:academic_year_id => academic_year_id, :vehicle_id => vehicle_id}
          old_route.send(:update_without_callbacks)
          old_route
        else
          new_route = Route.new(:name =>  "#{values[:name]} #{i}", :fare => values[:fare], :academic_year_id => academic_year_id, :vehicle_id => vehicle_id)
          new_route.send(:create_without_callbacks)
          old_route.transport_additional_details.each do |addl|
            addl_detail = new_route.transport_additional_details.build(:transport_additional_field_id => 
                addl.transport_additional_field_id, :additional_info => addl.additional_info)
            addl_detail.send(:create_without_callbacks)
          end
          new_route
        end
        values[:stops].each_with_index do |stop, s_i|
          new_stop = route.route_stops.build(:vehicle_stop_id => stop[:stop_id], :fare => stop[:fare], :stop_order => s_i+1)
          new_stop.send(:create_without_callbacks)
        end
      end
    end
    log.debug("Route updated and Route stops created")
    transports = Transport.all(:include => :receiver)
    routes = Route.all(:include => :route_stops)
    transports.each do |trans|
      if trans.receiver.present?
        route = routes.detect{|r| r.vehicle_id == trans.vehicle_id}
        stop_id = all_stops[trans.route_id]
        if route.nil? or stop_id.nil?
          log.debug("No route or stop - Transport id: #{trans.id}, Vehicle id: #{trans.vehicle_id}, Route_id: #{trans.route_id}") 
        else
          trans.attributes = {:academic_year_id => academic_year_id, :mode => 1, :pickup_route_id => route.try(:id), 
            :drop_route_id => route.try(:id), :pickup_stop_id => stop_id, :drop_stop_id => stop_id}
          trans.send(:update_without_callbacks)
        end
      end
    end
    log.debug("Transport updated")
    delete_routes.each do |r|
      TransportOldData.create(:model_name => r.class.to_s, :model_id=> r.id, :data_rows => r.attributes)
      r.delete
    end
    log.debug("Sub routes deleted")
  end
  log.debug("Finished" + Time.now.to_s)
end