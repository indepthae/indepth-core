class MultiFeesTransactionsFinanceTransactions < ActiveRecord::Migration
  def self.up
     create_table :multi_fees_transactions_finance_transactions, :id => false do |t|
       t.integer  :multi_fees_transaction_id
       t.integer  :finance_transaction_id
     end
  end

  def self.down
    drop_table :multi_fees_transactions_finance_transactions
  end
end
