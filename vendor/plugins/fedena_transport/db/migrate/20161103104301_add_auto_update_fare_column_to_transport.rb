class AddAutoUpdateFareColumnToTransport < ActiveRecord::Migration
  def self.up
    add_column :transports, :auto_update_fare,  :boolean, :default=>false
  end


  def self.down
    remove_column :transports, :auto_update_fare
  end
end
