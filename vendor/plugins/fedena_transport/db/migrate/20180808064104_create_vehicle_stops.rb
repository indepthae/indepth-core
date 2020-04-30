class CreateVehicleStops < ActiveRecord::Migration
  def self.up
    create_table :vehicle_stops do |t|
      t.references :academic_year
      t.string :name
      t.string :landmark
      t.decimal :latitude, :precision => 10, :scale => 6
      t.decimal :longitude, :precision => 10, :scale => 6
      t.boolean :is_active, :default => true
      t.references :school

      t.timestamps
    end
  end

  def self.down
    drop_table :vehicle_stops
  end
end
