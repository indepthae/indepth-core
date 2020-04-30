class AddAmountsAndTaxModeFieldsToFinanceFees < ActiveRecord::Migration
  def self.up
    add_column :finance_fees, :particular_total, :decimal, :precision => 15, :scale => 4, :null => true
    add_column :finance_fees, :discount_amount, :decimal, :precision => 15, :scale => 4, :null => true
    add_column :finance_fees, :tax_amount, :decimal, :precision => 15, :scale => 4, :null => true, :default => 0
    add_column :finance_fees, :tax_enabled, :boolean, :default => false
  end

  def self.down
    remove_column :finance_fees, :tax_enabled
    remove_column :finance_fees, :tax_amount
    remove_column :finance_fees, :discount_amount
    remove_column :finance_fees, :particular_total
  end
end
