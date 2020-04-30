class ChangeInstantFeeTables < ActiveRecord::Migration
  def self.up
    change_column :instant_fee_details, :amount, :decimal, :precision => 15, :scale => 4
    change_column :instant_fee_details, :discount, :decimal, :precision => 15, :scale => 4
    change_column :instant_fee_details, :net_amount, :decimal, :precision => 15, :scale => 4
    change_column :instant_fee_particulars, :amount, :decimal, :precision => 15, :scale => 4
    change_column :instant_fees, :amount, :decimal, :precision => 15, :scale => 4
  end

  def self.down
  end
end
