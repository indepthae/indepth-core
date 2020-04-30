class AddIndicesOnFinanceTransactionReceiptRecords < ActiveRecord::Migration
  def self.up
    add_index :finance_transaction_receipt_records, [:finance_transaction_id, :transaction_receipt_id], :name => "index_by_transaction_and_receipt"    
  end

  def self.down
    remove_index :finance_transaction_receipt_records, :name => "index_by_transaction_and_receipt"    
  end
end
