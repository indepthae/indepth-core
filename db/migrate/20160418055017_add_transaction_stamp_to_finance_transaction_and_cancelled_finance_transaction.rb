class AddTransactionStampToFinanceTransactionAndCancelledFinanceTransaction < ActiveRecord::Migration
  def self.up
    add_column :finance_transactions, :transaction_stamp, :integer, :limit => 5
    add_column :cancelled_finance_transactions, :transaction_stamp, :integer, :limit => 5
  end

  def self.down
    remove_column :cancelled_finance_transactions, :transaction_stamp
    remove_column :finance_transactions, :transaction_stamp
  end
end
