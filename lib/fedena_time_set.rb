# To change this template, choose Tools | Templates
# and open the template in the editor.

module FedenaTimeSet

    def self.current_time_to_local_time current_time
    server_time_to_gmt = current_time.getgm
    local_tzone_time = current_time
    time_zone = Configuration.find_by_config_key("TimeZone")
    unless time_zone.nil?
      unless time_zone.config_value.nil?
        zone = TimeZone.find_by_id(time_zone.config_value)
        if zone.present?
          if zone.difference_type=="+"
            local_tzone_time = server_time_to_gmt + zone.time_difference
          else
            local_tzone_time = server_time_to_gmt - zone.time_difference
          end
        end
      end
    end
    return local_tzone_time
  end

end

  
  # To change this template, choose Tools | Templates
# and open the template in the editor.

#module FedenaTimeSet
#
#  def self.current_time_to_local_time current_time
#    server_time_to_gmt = current_time.getgm
#    local_tzone_time = current_time
#    @time_zone ||= Configuration.find_by_config_key("TimeZone")
#    unless @time_zone.nil?
#      unless @time_zone.config_value.nil?
#        @zone ||= TimeZone.find_by_id(@time_zone.config_value)
#        if @zone.present?
#          if @zone.difference_type=="+"
#            local_tzone_time = server_time_to_gmt + @zone.time_difference
#          else
#            local_tzone_time = server_time_to_gmt - @zone.time_difference
#          end
#        end
#      end
#    end
#    return local_tzone_time
#  end
#
#end
