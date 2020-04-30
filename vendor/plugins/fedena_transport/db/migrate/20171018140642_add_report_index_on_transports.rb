class AddReportIndexOnTransports < ActiveRecord::Migration
  def self.up
    add_index :transports, [:receiver_id, :receiver_type], :name => 'index_on_receiver'
    add_index :transports, [:route_id]
  end

  def self.down
    remove_index :transports, [:receiver_id, :receiver_type], :name => 'index_on_receiver'
    remove_index :transports, [:route_id]
  end
end