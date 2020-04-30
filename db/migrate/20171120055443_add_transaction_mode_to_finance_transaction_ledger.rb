class AddTransactionModeToFinanceTransactionLedger < ActiveRecord::Migration
  def self.up
    add_column :finance_transaction_ledgers, :transaction_mode, :string, :limit => 10
  end

  def self.down
    remove_column :finance_transaction_ledgers, :transaction_mode
  end
end
