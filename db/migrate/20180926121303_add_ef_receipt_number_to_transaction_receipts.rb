class AddEfReceiptNumberToTransactionReceipts < ActiveRecord::Migration
  def self.up
    add_column :transaction_receipts, :ef_receipt_number, :string
    add_index :transaction_receipts, :ef_receipt_number
  end

  def self.down
    remove_index :transaction_receipts, :ef_receipt_number
    remove_column :transaction_receipts, :ef_receipt_number
  end
end
