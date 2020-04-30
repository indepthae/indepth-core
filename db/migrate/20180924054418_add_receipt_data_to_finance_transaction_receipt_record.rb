class AddReceiptDataToFinanceTransactionReceiptRecord < ActiveRecord::Migration
  def self.up
    add_column :finance_transaction_receipt_records, :receipt_data, :longtext
  end

  def self.down
    remove_column :finance_transaction_receipt_records, :receipt_data
  end
end
