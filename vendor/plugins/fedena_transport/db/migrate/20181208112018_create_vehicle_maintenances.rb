class CreateVehicleMaintenances < ActiveRecord::Migration
  def self.up
    create_table :vehicle_maintenances do |t|
      t.references :vehicle
      t.string :name
      t.text :notes
      t.date :maintenance_date
      t.date :next_maintenance_date
      t.decimal :amount, :precision => 15, :scale => 4

      t.timestamps
    end
  end

  def self.down
    drop_table :vehicle_maintenances
  end
end
