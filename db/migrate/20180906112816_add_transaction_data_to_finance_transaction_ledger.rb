class AddTransactionDataToFinanceTransactionLedger < ActiveRecord::Migration
  def self.up
    add_column :finance_transaction_ledgers, :transaction_data, :longtext
  end

  def self.down
    remove_column :finance_transaction_ledgers, :transaction_data
  end
end
