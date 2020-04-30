class AddFieldsToTransportGpsSettings < ActiveRecord::Migration
  def self.up
    add_column :transport_gps_settings, :vendor_name, :string
    add_column :transport_gps_settings, :vendor_code, :string
    add_column :transport_gps_settings, :integration_id, :integer
    add_column :transport_gps_settings, :integration_vector, :string
    add_column :transport_gps_settings, :sync_applicable, :boolean
  end

  def self.down
    remove_column :transport_gps_settings, :vendor_name
    remove_column :transport_gps_settings, :vendor_code
    remove_column :transport_gps_settings, :integration_id
    remove_column :transport_gps_settings, :integration_vector
    remove_column :transport_gps_settings, :sync_applicable
  end
end
