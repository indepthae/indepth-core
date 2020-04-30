class CreateRouteStops < ActiveRecord::Migration
  def self.up
    create_table :route_stops do |t|
      t.references :route
      t.references :vehicle_stop
      t.integer :stop_order
      t.time :pickup_time
      t.time :drop_time
      t.decimal :fare, :precision => 15, :scale => 4
      t.decimal :distance, :precision => 15, :scale => 4
      t.references :school

      t.timestamps
    end
  end

  def self.down
    drop_table :route_stops
  end
end
