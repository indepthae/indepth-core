class ChangeTransportTables < ActiveRecord::Migration
  def self.up
    change_column :transport_fees, :bus_fare, :decimal, :precision => 8, :scale => 4
  end

  def self.down
  end
end
