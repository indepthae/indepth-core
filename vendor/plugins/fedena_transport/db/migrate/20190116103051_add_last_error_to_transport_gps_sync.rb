class AddLastErrorToTransportGpsSync < ActiveRecord::Migration
  def self.up
      add_column :transport_gps_syncs, :last_error, :longtext
  end

  def self.down
    remove_column :transport_gps_syncs, :last_error
  end
end
