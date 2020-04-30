class AddIndicesOnFinanceTransactionReceiptRecordsForFeeAccount < ActiveRecord::Migration
  def self.up
    add_index :finance_transaction_receipt_records, :fee_account_id, :name => "index_by_fee_account"
  end

  def self.down
    remove_index :finance_transaction_receipt_records, :name => "index_by_fee_account"
  end
end
