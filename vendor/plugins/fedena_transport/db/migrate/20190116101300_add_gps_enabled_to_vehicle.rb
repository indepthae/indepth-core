class AddGpsEnabledToVehicle < ActiveRecord::Migration
  def self.up
      add_column :vehicles, :gps_enabled, :boolean, :default => false
  end

  def self.down
     remove_column :vehicles, :gps_enabled
  end
end
