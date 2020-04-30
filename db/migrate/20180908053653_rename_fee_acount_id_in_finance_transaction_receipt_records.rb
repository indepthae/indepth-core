class RenameFeeAcountIdInFinanceTransactionReceiptRecords < ActiveRecord::Migration
  def self.up
    rename_column :finance_transaction_receipt_records, :fee_acount_id, :fee_account_id
  end

  def self.down
    rename_column :finance_transaction_receipt_records, :fee_account_id, :fee_acount_id
  end
end
