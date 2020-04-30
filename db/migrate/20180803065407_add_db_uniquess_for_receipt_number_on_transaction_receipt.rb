class AddDbUniquessForReceiptNumberOnTransactionReceipt < ActiveRecord::Migration
  def self.up    
    add_index :transaction_receipts, [:receipt_sequence, :receipt_number, :school_id], :unique => true, :name => :school_receipt_uniqueness
  end

  def self.down
    remove_index :transaction_receipts, :name => :school_receipt_uniqueness
  end
end
