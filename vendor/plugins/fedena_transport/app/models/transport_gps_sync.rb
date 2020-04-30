class TransportGpsSync < ActiveRecord::Base
  require "net/http"
  require "uri"
  require 'json'
  
  after_create :sync_transport_data 
  
  SYNC_STATUS= {0=> "Queueing",1=> "Syncing", 2=> "Completed", 3=> "Failed" }.freeze
  
  
  def show_status
    return SYNC_STATUS[self.status.to_i]
  end
  
  def sync_transport_data
    self.update_attributes(:status => 0)
    Delayed::Job.enqueue(self, {:queue => "transport_gps_sync"})
  end
  
  def perform
    started_time = FedenaTimeSet.current_time_to_local_time(Time.now)
    self.update_attributes(:started_at=>started_time,:status => 1)
    @sync = TransportGpsSync.find_by_id(self.id)
    @errors = false
    @status = " "
    url_array = YAML.load_file(File.join(File.dirname(__FILE__),"../..","config","gps_settings.yml"))
    @url = url_array["url"] + "/api/v1/routes/sync"
    academic_year_id = AcademicYear.active.first.try(:id)
    @working_days_ids = WeekdaySet.common.weekday_ids
    @active_gps_setting = TransportGpsSetting.first
    @time_zone = time_zone_for_school
    @vehicle_stop_array,vehicle_stops_ids = gps_enabled_vehicle_stops #vehicle_stop and vehicle_stops_ids
    @vehicle_array,vehicles_ids = gps_enabled_vehicles(academic_year_id) #vehicles and vehicle_ids
    @route_array = gps_enabled_routes(academic_year_id,vehicle_stops_ids,vehicles_ids) #routes
    @transport_sync_hash = {"api_key"=>@active_gps_setting.client_id,
      "working_days"=>@working_days_ids,"time_zone"=>@time_zone,
      "stops"=> @vehicle_stop_array,"vehicles"=>@vehicle_array,"routes"=> @route_array}
    @errors,@status = send_request_to_gps_server(@active_gps_setting.client_secret,@transport_sync_hash.to_json) 
    completed_at = FedenaTimeSet.current_time_to_local_time(Time.now)
    if @errors
      @sync.update_attributes(:completed_at=> completed_at,:status => 3,:last_error=>@status)
    else
      @sync.update_attributes(:completed_at=> completed_at,:status => 2)
    end
  end
  
  def gps_enabled_vehicle_stops
    vehicle_stop_array =[]
    vehicle_stops = VehicleStop.with_gps_data.active
    vehicle_stops_ids = vehicle_stops.collect(&:id)
    vehicle_stops.each do |vs| 
      stop_hash ={}
      stop_hash["id"],stop_hash["stop_name"] = vs.id,vs.name
      stop_hash["latitude"],stop_hash["longitude"] = vs.latitude.to_f,vs.longitude.to_f
      stop_hash["landmark"] = vs.landmark 
      vehicle_stop_array.push(stop_hash)
    end
    return vehicle_stop_array,vehicle_stops_ids
  end
  
  def gps_enabled_vehicles(academic_year_id)
    vehicle_array=[] 
    vehicles = Vehicle.active_in_academic_year(academic_year_id).all(:conditions=>["gps_enabled=?",true])
    vehicles_ids = vehicles.collect(&:id)
    vehicles.each do |v| 
      vehicle_hash={}
      vehicle_hash["id"],vehicle_hash["seat_capacity"] = v.id,v.no_of_seats
      vehicle_hash["gps_number"],vehicle_hash["reg_number"] = v.gps_number,v.vehicle_no
      vehicle_array.push(vehicle_hash)
    end
    return vehicle_array,vehicles_ids
  end
  
  def gps_enabled_routes(academic_year_id,vehicle_stops_ids,vehicles_ids)
    route_array =[]
    routes =  Route.in_academic_year(academic_year_id) 
    routes.each do |route|
      if vehicles_ids.include?(route.vehicle_id)
        v_route_stops = route.route_stops.with_gps_data.all(:order=>"stop_order,pickup_time",
          :conditions=>["vehicle_stop_id in (?)",vehicle_stops_ids]) 
        pickup_times = v_route_stops.collect(&:pickup_time)
        drop_times = v_route_stops.collect(&:drop_time)
        route_hash = {"id"=>route.id,"name"=>route.name,"vehicle_id"=>route.vehicle_id,
          "category"=>"Two Way","driver_name"=>route.driver.try(:full_name),
          "helper_name"=>route.attendant.try(:full_name),"helper_phone"=>route.attendant.try(:mobile_phone),
          "pickup_start_time"=>pickup_times.min,"pickup_end_time"=>pickup_times.max,
          "drop_start_time"=>drop_times.min,"drop_end_time"=>drop_times.max
        }
        route_hash["stops"] = gps_enabled_route_stop(v_route_stops) #route stop for that route
        route_array.push(route_hash)
      end
    end
    return route_array
  end
  
  def gps_enabled_route_stop(v_route_stops)
    route_stops_array=[]
    v_route_stops.each do |r_stop|
      r_stop_hash={"id"=>r_stop.vehicle_stop_id,"pickup"=>r_stop.pickup_time,"drop"=>r_stop.drop_time}
      route_stops_array.push(r_stop_hash)
    end
    return route_stops_array
  end
  
  def time_zone_for_school
    config_time_zone = Configuration.find_by_config_key("TimeZone")
    unless config_time_zone.nil?
      unless config_time_zone.config_value.nil?
        zone = TimeZone.find_by_id(config_time_zone.config_value)
        time_zone = zone.difference_type + Time.at(zone.time_difference).utc.strftime("%I:%M")
      end
    end
    return time_zone
  end
  
  def send_request_to_gps_server(client_secret,transport_sync_hash)
    errors = false
    begin
      uri = URI.parse(@url)
      http = Net::HTTP.new(uri.host, uri.port)
      if uri.scheme=="https"
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
      req = Net::HTTP::Post.new(uri.path, {'Content-Type' =>'application/json',
          'API-SECRET' =>client_secret})
      req.body = transport_sync_hash
      res = http.request(req)
      #puts "response #{res.body}"
      #puts "response status #{res.code}"
      case res
      when Net::HTTPSuccess then status = "Success"
      when Net::HTTPServerError then status = "Server error"; errors = true
      when Net::HTTPClientError then status = "check GPS setting"; errors = true  
      end
      #puts "status===================#{status}"
    rescue => e
      puts "failed #{e}"
      errors = true
      status = ["#{e}"]
    end
    return errors,status
  end
  
end
