class CreateAdvanceFeeTransactionReceiptRecords < ActiveRecord::Migration
  def self.up
    create_table :advance_fee_transaction_receipt_records do |t|
      t.references :advance_fee_collection
      t.references :transaction_receipt
      t.integer :fee_account_id
      t.integer :fee_receipt_template_id
      t.integer :precision_count
      t.text :receipt_data
      t.integer :school_id

      t.timestamps
    end
  end

  def self.down
    drop_table :advance_fee_transaction_receipt_records
  end
end