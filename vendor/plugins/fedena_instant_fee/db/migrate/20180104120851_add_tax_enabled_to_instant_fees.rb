class AddTaxEnabledToInstantFees < ActiveRecord::Migration
  def self.up
    add_column :instant_fees, :tax_enabled, :boolean, :default => false
  end

  def self.down
    remove_column :instant_fees, :tax_enabled
  end
end
