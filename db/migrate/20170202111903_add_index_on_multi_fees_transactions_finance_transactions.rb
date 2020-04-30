class AddIndexOnMultiFeesTransactionsFinanceTransactions < ActiveRecord::Migration
  def self.up
    add_index :multi_fees_transactions_finance_transactions, :multi_fees_transaction_id,:name => 'index_on_multi_fees_transaction_id'
    add_index :multi_fees_transactions_finance_transactions, :finance_transaction_id,:name => 'index_on_finance_transaction_id'
  end

  def self.down
    remove_index :multi_fees_transactions_finance_transactions, :multi_fees_transaction_id
    remove_index :multi_fees_transactions_finance_transactions, :finance_transaction_id
  end
end
