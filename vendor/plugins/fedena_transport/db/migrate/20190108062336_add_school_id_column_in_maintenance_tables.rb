class AddSchoolIdColumnInMaintenanceTables < ActiveRecord::Migration
  def self.up
    add_column :vehicle_maintenances, :school_id, :integer
    add_column :vehicle_maintenance_attachments, :school_id, :integer
    execute "UPDATE vehicle_maintenances INNER JOIN vehicles ON vehicles.id = vehicle_id SET vehicle_maintenances.school_id = vehicles.school_id"
    execute "UPDATE vehicle_maintenance_attachments INNER JOIN vehicle_maintenances ON vehicle_maintenances.id = vehicle_maintenance_id SET vehicle_maintenance_attachments.school_id = vehicle_maintenances.school_id"
  end

  def self.down
    remove_column :vehicle_maintenances, :school_id
    remove_column :vehicle_maintenance_attachments, :school_id
  end
end
