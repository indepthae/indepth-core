class ChangeFineAmountPrecisionFinanceTransaction < ActiveRecord::Migration
  def self.up
    change_column :finance_transactions, :fine_amount, :decimal, :precision=>15, :scale=>4
  end

  def self.down
    change_column :finance_transactions, :fine_amount, :decimal, :precision=>10, :scale=>4
  end
end
