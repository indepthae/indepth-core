class AddIsFinePaidAndBalanceFineToFinanceFee < ActiveRecord::Migration
  def self.up
    add_column :finance_fees, :is_fine_paid, :boolean
    add_column :finance_fees, :balance_fine, :decimal, :precision => 15, :scale => 2
  end

  def self.down
    remove_column :finance_fees, :is_fine_paid
    remove_column :finance_fees, :balance_fine
  end
end
