class AddRemaingIndexesToTransportTables < ActiveRecord::Migration
  def self.up
    add_index :transports, [:receiver_type, :receiver_id], :name => "index_on_r_type_id"
    add_index :archived_transports, [:receiver_type, :receiver_id], :name => "index_on_r_type_id"
    add_index :transport_attendances, [:receiver_type, :receiver_id], :name => "index_on_r_type_id"
    remove_index :transports, :name => "index_on_receiver"
    remove_index :archived_transports, :name => "index_on_receiver"
    remove_index :transport_attendances, :name => "index_on_receiver"
  end

  def self.down
    remove_index :transports, :name => "index_on_r_type_id"
    remove_index :archived_transports, :name => "index_on_r_type_id"
    remove_index :transport_attendances, :name => "index_on_r_type_id"
    add_index :transports, [:receiver_id, :receiver_type], :name => "index_on_receiver"
    add_index :archived_transports, [:receiver_id, :receiver_type], :name => "index_on_receiver"
    add_index :transport_attendances, [:receiver_id, :receiver_type], :name => "index_on_receiver"
  end
end
