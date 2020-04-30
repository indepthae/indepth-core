class StructureChangesInTransport < ActiveRecord::Migration
  def self.up
    change_column :transport_fees, :bus_fare, :decimal, :precision => 15, :scale => 4
    change_column :transports, :bus_fare, :decimal, :precision => 15, :scale => 4
  end

  def self.down
  end
end
