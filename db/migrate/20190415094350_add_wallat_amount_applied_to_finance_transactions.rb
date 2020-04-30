class AddWallatAmountAppliedToFinanceTransactions < ActiveRecord::Migration
  def self.up
    add_column :finance_transactions, :wallet_amount_applied, :boolean, :default => false
  end

  def self.down
    remove_column :finance_transactions, :wallet_amount_applied
  end
end
