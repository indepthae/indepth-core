# To change this license header, choose License Headers in Project Properties.
# To change this template file, choose Tools | Templates
# and open the template in the editor.

module TransportHelper
  
  def fetch_stops(route_type)
    stops = (route_type == "pickup" ? @pickup_stops : @drop_stops)
    stops = @stops||[] if stops.nil?
    return stops
  end

end
