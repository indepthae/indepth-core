class AddIndexesForTransactionLedger < ActiveRecord::Migration
  def self.up
    add_index :finance_transactions, :transaction_ledger_id, :name => :index_by_transaction_leger_id
    add_index :cancelled_finance_transactions, :transaction_ledger_id, :name => :index_by_transaction_leger_id
    add_index :finance_transaction_ledgers, :receipt_no, :name => :index_by_receipt_no
    add_index :finance_transaction_ledgers, [:payee_type, :payee_id, :status], :name => :index_by_payee_and_status
    add_index :finance_transaction_ledgers, :status, :name => :index_by_status
    add_index :finance_transaction_ledgers, :transaction_mode, :name => :index_by_transaction_mode    
  end

  def self.down
    remove_index :finance_transactions, :transaction_ledger_id, :name => :index_by_transaction_leger_id
    remove_index :cancelled_finance_transactions, :transaction_ledger_id, :name => :index_by_transaction_leger_id
    remove_index :finance_transaction_ledgers, :receipt_no, :name => :index_by_receipt_no
    remove_index :finance_transaction_ledgers, [:payee_type, :payee_id, :status], :name => :index_by_payee_and_status
    remove_index :finance_transaction_ledgers, :status, :name => :index_by_status
    remove_index :finance_transaction_ledgers, :transaction_mode, :name => :index_by_transaction_mode
  end
end
