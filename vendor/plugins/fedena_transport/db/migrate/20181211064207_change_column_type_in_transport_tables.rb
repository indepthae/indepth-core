class ChangeColumnTypeInTransportTables < ActiveRecord::Migration
  def self.up
    add_column :transport_passenger_imports, :last_message, :longtext
  end

  def self.down
    remove_column :transport_passenger_imports, :last_message
  end
end
