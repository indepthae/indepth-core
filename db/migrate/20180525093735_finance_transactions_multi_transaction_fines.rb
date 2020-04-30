class FinanceTransactionsMultiTransactionFines < ActiveRecord::Migration
  def self.up
    create_table :finance_transactions_multi_transaction_fines, :id => false do |t|
      t.integer :finance_transaction_id
      t.integer :multi_transaction_fine_id
    end
  end

  def self.down
    drop_table :finance_transactions_multi_transaction_fines
  end
end
