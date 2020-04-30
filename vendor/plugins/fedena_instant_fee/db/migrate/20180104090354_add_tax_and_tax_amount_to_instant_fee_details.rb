class AddTaxAndTaxAmountToInstantFeeDetails < ActiveRecord::Migration
  def self.up
    add_column :instant_fee_details, :tax, :decimal, :precision => 15, :scale => 4
    add_column :instant_fee_details, :tax_amount, :decimal, :precision => 15, :scale => 4
  end

  def self.down
    remove_column :instant_fee_details, :tax_amount
    remove_column :instant_fee_details, :tax
  end
end
