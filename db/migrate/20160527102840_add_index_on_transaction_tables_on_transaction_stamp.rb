class AddIndexOnTransactionTablesOnTransactionStamp < ActiveRecord::Migration
  def self.up
	add_index :finance_transactions, [:id, :transaction_stamp], :name => "index_on_finance_transaction_id_and_transaction_stamp"
	add_index :cancelled_finance_transactions, [:finance_transaction_id, :transaction_stamp], :name => "index_on_finance_transaction_id_and_transaction_stamp"
  end

  def self.down
	remove_index :finance_transactions, [:id, :transaction_stamp], :name => "index_on_finance_transaction_id_and_transaction_stamp"
	remove_index :cancelled_finance_transactions, [:finance_transaction_id, :transaction_stamp], :name => "index_on_finance_transaction_id_and_transaction_stamp"
  end
end
