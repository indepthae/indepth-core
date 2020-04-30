class AddTransactionReceiptIdToAdvanceFeeCollections < ActiveRecord::Migration
  def self.up
    add_column :advance_fee_collections, :transaction_receipt_id, :integer, :default => nil
  end

  def self.down
    remove_column :transaction_receipt_id
  end
end
