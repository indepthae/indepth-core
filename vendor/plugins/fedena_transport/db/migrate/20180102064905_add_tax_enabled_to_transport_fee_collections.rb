class AddTaxEnabledToTransportFeeCollections < ActiveRecord::Migration
  def self.up
    add_column :transport_fee_collections, :tax_enabled, :boolean, :default => false
  end

  def self.down
    remove_column :transport_fee_collections, :tax_enabled
  end
end
