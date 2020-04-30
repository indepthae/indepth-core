class AddIndicesForSchoolStatsTransport < ActiveRecord::Migration
  def self.up
    add_index :transports, :vehicle_id
  end

  def self.down
    remove_index :transports, :vehicle_id
  end
end
