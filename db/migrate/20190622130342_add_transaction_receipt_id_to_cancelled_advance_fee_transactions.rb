class AddTransactionReceiptIdToCancelledAdvanceFeeTransactions < ActiveRecord::Migration
  def self.up
  	add_column :cancelled_advance_fee_transactions, :transaction_receipt_id, :integer, :default => nil
  end

  def self.down
  	remove_column :cancelled_advance_fee_transactions, :transaction_receipt_id
  end
end
