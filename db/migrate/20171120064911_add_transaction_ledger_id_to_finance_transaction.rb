class AddTransactionLedgerIdToFinanceTransaction < ActiveRecord::Migration
  def self.up
    add_column :finance_transactions, :transaction_ledger_id, :integer
  end

  def self.down
    remove_column :finance_transactions, :transaction_ledger_id
  end
end
