class AlterTransportTables < ActiveRecord::Migration
  def self.up
    rename_table :route_vehicle_additional_fields, :transport_additional_fields
    rename_table :route_vehicle_additional_details, :transport_additional_details
    rename_column :transport_additional_details, :route_vehicle_additional_field_id, :transport_additional_field_id
    
    #vehicle
    add_column :vehicles, :academic_year_id, :integer
    add_column :vehicles, :vehicle_type, :integer
    add_column :vehicles, :vehicle_model, :string
    add_column :vehicles, :gps_number, :string
    
    #route
    rename_column :routes, :destination, :name
    rename_column :routes, :cost, :fare
    change_column :routes, :fare, :decimal, :precision => 15, :scale => 4
    add_column :routes, :academic_year_id, :integer
    add_column :routes, :vehicle_id, :integer
    add_column :routes, :driver_id, :integer
    add_column :routes, :attendant_id, :integer
    add_column :routes, :fare_updating_status, :integer
    add_column :routes, :is_active, :boolean, :default => true
    
    #transport
    add_column :transports, :academic_year_id, :integer
    add_column :transports, :mode, :integer
    add_column :transports, :pickup_route_id, :integer
    add_column :transports, :pickup_stop_id, :integer
    add_column :transports, :drop_route_id, :integer
    add_column :transports, :drop_stop_id, :integer
    add_column :transports, :applied_from, :date
    add_column :transports, :remove_fare, :boolean, :default => false
    change_column :transports, :auto_update_fare, :boolean, :default => true
    
  end

  def self.down
    rename_table :transport_additional_fields, :route_vehicle_additional_fields
    rename_table :transport_additional_details, :route_vehicle_additional_details
    rename_column :transport_additional_details, :transport_additional_field_id, :route_vehicle_additional_field_id
    
    #vehicle
    remove_column :vehicles, :academic_year_id
    remove_column :vehicles, :vehicle_type
    remove_column :vehicles, :vehicle_model
    remove_column :vehicles, :gps_number
    
    #route
    rename_column :routes, :name, :destination
    rename_column :routes, :fare, :cost
    remove_column :routes, :academic_year_id
    remove_column :routes, :vehicle_id
    remove_column :routes, :driver_id
    remove_column :routes, :attendant_id
    remove_column :routes, :fare_updating_status
    
    #transport
    remove_column :transports, :academic_year_id
    remove_column :transports, :mode
    remove_column :transports, :pickup_route_id
    remove_column :transports, :pickup_stop_id
    remove_column :transports, :drop_route_id
    remove_column :transports, :drop_stop_id
    remove_column :transports, :applied_from
    remove_column :transports, :remove_fare
    change_column :transports, :auto_update_fare, :boolean, :default => false
  end
end
