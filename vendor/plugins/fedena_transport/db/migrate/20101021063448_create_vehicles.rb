class CreateVehicles < ActiveRecord::Migration
  def self.up
    create_table :vehicles do |t|
      t.string     :vehicle_no
      t.references :main_route
      t.integer    :no_of_seats
      t.string     :status
      t.timestamps
    end
  end

  def self.down
    drop_table :vehicles
  end
end
