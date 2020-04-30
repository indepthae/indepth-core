module FedenaTransport
  
  module EmployeeExtension
    def self.included(base)
      base.instance_eval do
        attr_accessor :enable_transport
        has_many :transport_fees, :as => 'receiver'
        has_many :routes, :foreign_key => :driver_id
        has_many :transports, :as => 'receiver', :dependent => :destroy
        has_many :archived_transports, :as => 'receiver', :dependent => :destroy
        has_one :transport, :as => 'receiver', :dependent => :destroy, :include => :academic_year, :conditions => "academic_years.is_active = true"
        
        before_destroy :handle_transport_data

        accepts_nested_attributes_for :transport_fees
        accepts_nested_attributes_for :transport, :allow_destroy => true

        named_scope :employee_transport_details, lambda{|academic_year_id| 
          {:select => "employees.id, CONCAT(first_name, ' ', middle_name, ' ', last_name) AS name, employee_number, 
employee_departments.name as department_name, employee_positions.name as position_name, employee_departments.id as department_id, 
IF(transports.id <=> NULL, false, true) AS allocation_status, transports.mode AS allocation_type, 
p_route.name AS pickup_route, d_route.name AS drop_route, p_stop.name AS pickup_stop, d_stop.name AS drop_stop,
            p_vehicle.vehicle_no AS pickup_vehicle, d_vehicle.vehicle_no AS drop_vehicle", 
            :joins => "INNER JOIN employee_departments ON employee_departments.id = employees.employee_department_id 
INNER JOIN employee_positions ON employee_positions.id = employees.employee_position_id
LEFT OUTER JOIN transports on transports.receiver_type = 'Employee' AND transports.receiver_id = employees.id AND transports.academic_year_id = #{academic_year_id}
LEFT OUTER JOIN routes AS p_route ON p_route.id = transports.pickup_route_id 
LEFT OUTER JOIN vehicles AS p_vehicle ON p_route.vehicle_id = p_vehicle.id 
LEFT OUTER JOIN routes AS d_route ON d_route.id = transports.drop_route_id 
LEFT OUTER JOIN vehicles AS d_vehicle ON d_route.vehicle_id = d_vehicle.id 
LEFT OUTER JOIN vehicle_stops AS p_stop ON p_stop.id = transports.pickup_stop_id 
LEFT OUTER JOIN vehicle_stops AS d_stop ON d_stop.id = transports.drop_stop_id", 
            :group => 'employees.id'
          }
        }
        
        named_scope :department_wise_employee_transport, lambda{|department_ids|
          { :conditions => ["employee_departments.id IN (?)", department_ids] 
          }
        }
        
        named_scope :alotted_employee_transports, :conditions => ["transports.id IS NOT NULL"]
        
        named_scope :transport_sort_order, lambda{|s_order|
          { :order => s_order
          }
        }
        
        named_scope :route_filter, lambda{|route_type, value|
          {
            :conditions => ["#{route_type}_route_id = ?", value]
          }
        }
      end
      
      def handle_transport_data
        archived_record = ArchivedEmployee.find_by_former_id(self.id)
        self.transports.each{|t| t.archive_transport({:remove_fare => 1}, archived_record.id, archived_record.class.to_s)} if archived_record.present?
      end
    end
    
    def emp_department_name
      employee_department.name
    end
    
    def transport_allocation_status
      (allocation_status == "1" ? t('alloted') : t('not_alloted'))
    end
    
    def transport_allocation_type
      t(Transport::TRANSPORT_MODE[allocation_type.to_i]) if allocation_type.present?
    end
        
    def stop(route_type)
      send("#{route_type}_stop")
    end
    
    def vehicle_name(route_type)
      send("#{route_type}_vehicle")
    end 
  end
  
end