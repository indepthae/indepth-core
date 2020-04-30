class AddIsActiveToTaxPayment < ActiveRecord::Migration
  def self.up
    add_column :tax_payments, :is_active, :boolean, :default => true
    add_index :tax_payments, :is_active, :name => "by_active"
  end

  def self.down
    remove_index :tax_payments, :name => "by_active"
    remove_column :tax_payments, :is_active
  end
end
