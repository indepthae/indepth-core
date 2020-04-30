class AddIndexForTransactionDate < ActiveRecord::Migration
  def self.up
    add_index :finance_transactions, [:transaction_date]
  end

  def self.down
    remove_index :finance_transactions, [:transaction_date]
  end
end
