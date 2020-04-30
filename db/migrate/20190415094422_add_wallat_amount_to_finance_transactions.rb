class AddWallatAmountToFinanceTransactions < ActiveRecord::Migration
  def self.up
    add_column :finance_transactions, :wallet_amount, :decimal, :precision =>15, :scale => 2, :nil => false, :default => 0.00
  end

  def self.down
    remove_column :finance_transactions,:wallet_amount
  end
end
