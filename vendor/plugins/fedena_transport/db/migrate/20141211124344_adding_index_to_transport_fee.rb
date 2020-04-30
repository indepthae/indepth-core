class AddingIndexToTransportFee < ActiveRecord::Migration
  def self.up
    add_index :transport_fees,:bus_fare
  end

  def self.down
    remove_index :transport_fees,:bus_fare
  end
end
