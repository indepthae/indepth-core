class AddIndexToFinanceTransaction < ActiveRecord::Migration
  def self.up
    add_index :finance_transactions, [:wallet_amount_applied],  :name => "index_on_wallet_amount_applied"
  end

  def self.down
    remove_index :finance_transactions, [:wallet_amount_applied]
  end
end
