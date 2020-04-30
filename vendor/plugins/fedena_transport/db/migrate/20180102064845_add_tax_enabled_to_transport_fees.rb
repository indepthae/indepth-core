class AddTaxEnabledToTransportFees < ActiveRecord::Migration
  def self.up
    add_column :transport_fees, :tax_enabled, :boolean, :default => false
  end

  def self.down
    remove_column :transport_fees, :tax_enabled
  end
end
