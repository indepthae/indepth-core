module VehicleStopsHelper
  
  def fetch_path(stop)
    stop.new_record? ? vehicle_stops_path : vehicle_stop_path
  end
  
end
