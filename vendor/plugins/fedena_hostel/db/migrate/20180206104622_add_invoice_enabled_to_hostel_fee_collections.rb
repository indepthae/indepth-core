class AddInvoiceEnabledToHostelFeeCollections < ActiveRecord::Migration
  def self.up
    add_column :hostel_fee_collections, :invoice_enabled, :boolean, :default => false
  end

  def self.down
    remove_column :hostel_fee_collections, :invoice_enabled
  end
end
