class AddTransactionLedgerIdToCancelledFinanceTransaction < ActiveRecord::Migration
  def self.up
    add_column :cancelled_finance_transactions, :transaction_ledger_id, :integer
  end

  def self.down
    remove_column :cancelled_finance_transactions, :transaction_ledger_id
  end
end
