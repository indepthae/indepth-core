class AddInvoiceEnabledToTransportFeeCollections < ActiveRecord::Migration
  def self.up
    add_column :transport_fee_collections, :invoice_enabled, :boolean, :default => false
  end

  def self.down
    remove_column :transport_fee_collections, :invoice_enabled
  end
end
