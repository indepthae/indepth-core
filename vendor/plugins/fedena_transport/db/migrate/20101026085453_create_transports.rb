class CreateTransports < ActiveRecord::Migration
  def self.up
    create_table :transports do |t|
      t.references :user
      t.references :vehicle
      t.references :route
      t.string     :bus_fare
      t.timestamps
    end
  end

  def self.down
    drop_table :transports
  end
end
