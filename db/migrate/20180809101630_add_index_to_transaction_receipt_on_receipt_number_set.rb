class AddIndexToTransactionReceiptOnReceiptNumberSet < ActiveRecord::Migration
  def self.up
    add_index :transaction_receipts, :receipt_number_set_id, :name => "index_by_receipt_number_set"
  end

  def self.down
    remove_index :transaction_receipts, :name => "index_by_receipt_number_set"
  end
end
