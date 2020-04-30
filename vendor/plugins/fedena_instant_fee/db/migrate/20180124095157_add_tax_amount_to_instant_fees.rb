class AddTaxAmountToInstantFees < ActiveRecord::Migration
  def self.up
    add_column :instant_fees, :tax_amount, :decimal, :precision => 15, :scale => 4
  end

  def self.down
    remove_column :instant_fees, :tax_amount
  end
end
