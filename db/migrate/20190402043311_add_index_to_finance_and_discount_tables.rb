class AddIndexToFinanceAndDiscountTables < ActiveRecord::Migration
  def self.up
    add_index :particular_payments, :finance_transaction_id, :name => "index_on_finance_transaction_id"
    add_index :finance_transaction_receipt_records, :finance_transaction_id, :name => "index_on_finance_transaction_id"
    add_index :finance_transaction_receipt_records, :transaction_receipt_id, :name => "index_on_transaction_receipt_id"
    add_index :multi_fee_discounts, :transaction_ledger_id, :name => "index_on_transaction_ledger_id"
    add_index :fee_discounts, :finance_transaction_id, :name => "index_on_finance_transaction_id"
  end

  def self.down
    remove_index :particular_payments, :name => "index_on_finance_transaction_id"
    remove_index :finance_transaction_receipt_records, :name => "index_on_finance_transaction_id"
    remove_index :finance_transaction_receipt_records, :name => "index_on_transaction_receipt_id"
    remove_index :multi_fee_discounts, :name => "index_on_transaction_ledger_id"
    remove_index :fee_discounts, :name => "index_on_finance_transaction_id"
  end
end
