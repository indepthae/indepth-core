class AddTaxEnabledToHostelFees < ActiveRecord::Migration
  def self.up
    add_column :hostel_fees, :tax_enabled, :boolean, :default => false
  end

  def self.down
    remove_column :hostel_fees, :tax_enabled
  end
end
