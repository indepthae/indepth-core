class AddWallatAmountAppliedToCancelledFinanceTransactions < ActiveRecord::Migration
  def self.up
    add_column :cancelled_finance_transactions, :wallet_amount_applied, :boolean, :default => false
  end

  def self.down
    remove_column :wallet_amount_applied
  end
end
