class AddIndexesToTransportTables < ActiveRecord::Migration
  def self.up
    #vehicle
    add_index :vehicles, :academic_year_id
    add_index :vehicles, :status
    
    #routes
    add_index :routes, :academic_year_id
    add_index :routes, [:is_active, :academic_year_id]
    add_index :routes, [:academic_year_id, :is_active, :school_id], :name => "index_on_active_in_academic_year"
    add_index :routes, :is_active
    add_index :routes, :vehicle_id
    add_index :routes, :driver_id
    add_index :routes, :attendant_id
    
    #transport
    add_index :transports, :academic_year_id
    add_index :transports, :pickup_route_id
    add_index :transports, :pickup_stop_id
    add_index :transports, :drop_route_id
    add_index :transports, :drop_stop_id
    add_index :transports, [:pickup_route_id, :drop_route_id], :name => "index_on_route"
    
    #vehicle_stops
    add_index :vehicle_stops, :academic_year_id
    add_index :vehicle_stops, [:is_active, :academic_year_id]
    add_index :vehicle_stops, :school_id
    
    #vehicle_certificates
    add_index :vehicle_certificates, :certificate_type_id
    add_index :vehicle_certificates, :vehicle_id
    add_index :vehicle_certificates, :school_id
    
    #route_stops
    add_index :route_stops, :route_id
    add_index :route_stops, :vehicle_stop_id
    add_index :route_stops, :school_id
    
    #certificate_types
    add_index :certificate_types, :send_reminders
    add_index :certificate_types, :is_active
    add_index :certificate_types, :school_id
    
    #route_employees
    add_index :route_employees, :employee_id
    add_index :route_employees, :school_id
    
    #archived_employees
    add_index :archived_transports, :academic_year_id
    add_index :archived_transports, :pickup_route_id
    add_index :archived_transports, :pickup_stop_id
    add_index :archived_transports, :drop_route_id
    add_index :archived_transports, :drop_stop_id
    add_index :archived_transports, [:pickup_route_id, :drop_route_id], :name => "index_on_route"
    add_index :archived_transports, [:receiver_id, :receiver_type], :name => "index_on_receiver"
    add_index :archived_transports, :school_id
    
    #transport_attendances
    add_index :transport_attendances, [:receiver_id, :receiver_type], :name => "index_on_receiver"
    add_index :transport_attendances, [:route_type, :route_id], :name => "index_on_route"
    add_index :transport_attendances, :school_id
    
    #transport_imports
    add_index :transport_imports, :import_from_id
    add_index :transport_imports, :import_to_id
    add_index :transport_imports, :school_id
    
    #transport_passenger_imports
    add_index :transport_passenger_imports, :academic_year_id
    add_index :transport_passenger_imports, :school_id
  end

  def self.down
    #vehicle
    remove_index :vehicles, :academic_year_id
    remove_index :vehicles, :status
    
    #routes
    remove_index :routes, :academic_year_id
    remove_index :routes, [:is_active, :academic_year_id]
    remove_index :routes, :name => "index_on_active_in_academic_year"
    remove_index :routes, :is_active
    remove_index :routes, :vehicle_id
    remove_index :routes, :driver_id
    remove_index :routes, :attendant_id
    
    #transport
    remove_index :transports, :academic_year_id
    remove_index :transports, :pickup_route_id
    remove_index :transports, :pickup_stop_id
    remove_index :transports, :drop_route_id
    remove_index :transports, :drop_stop_id
    remove_index :transports, :name => "index_on_route"
    
    #vehicle_stops
    remove_index :vehicle_stops, :academic_year_id
    remove_index :vehicle_stops, [:is_active, :academic_year_id]
    remove_index :vehicle_stops, :school_id
    
    #vehicle_certificates
    remove_index :vehicle_certificates, :certificate_type_id
    remove_index :vehicle_certificates, :vehicle_id
    remove_index :vehicle_certificates, :school_id
    
    #route_stops
    remove_index :route_stops, :route_id
    remove_index :route_stops, :vehicle_stop_id
    remove_index :route_stops, :school_id
    
    #certificate_types
    remove_index :certificate_types, :send_reminders
    remove_index :certificate_types, :is_active
    remove_index :certificate_types, :school_id
    
    #route_employees
    remove_index :route_employees, :employee_id
    remove_index :route_employees, :school_id
    
    #archived_employees
    remove_index :archived_transports, :academic_year_id
    remove_index :archived_transports, :pickup_route_id
    remove_index :archived_transports, :pickup_stop_id
    remove_index :archived_transports, :drop_route_id
    remove_index :archived_transports, :drop_stop_id
    remove_index :archived_transports, :name => "index_on_route"
    remove_index :archived_transports, :name => "index_on_receiver"
    remove_index :archived_transports, :school_id
    
    #transport_attendances
    remove_index :transport_attendances, :name => "index_on_receiver"
    remove_index :transport_attendances, :name => "index_on_route"
    remove_index :transport_attendances, :school_id
    
    #transport_imports
    remove_index :transport_imports, :import_from_id
    remove_index :transport_imports, :import_to_id
    remove_index :transport_imports, :school_id
    
    #transport_passenger_imports
    remove_index :transport_passenger_imports, :academic_year_id
    remove_index :transport_passenger_imports, :school_id
  end
end
