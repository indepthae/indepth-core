class AddingFieldsToMultifeediscountFeediscountFinancetransaction < ActiveRecord::Migration
  def self.up
    add_column :multi_fee_discounts, :transaction_ledger_id, :integer
    add_column :fee_discounts, :finance_transaction_id, :integer
    add_column :finance_transaction_ledgers, :is_waiver, :boolean, :default => false
  end

  def self.down
    remove_column :multi_fee_discounts, :transaction_ledger_id
    remove_column :fee_discounts, :finance_transaction_id
    remove_column :finance_transaction_ledgers, :is_waiver
  end
end
