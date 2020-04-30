class CreateFinanceTransactionReceiptRecords < ActiveRecord::Migration
  def self.up
    create_table :finance_transaction_receipt_records do |t|
      t.references :finance_transaction
      t.references :transaction_receipt
      t.integer :fee_acount_id
      t.integer :fee_receipt_template_id
      t.integer :precision_count
      t.integer :school_id

      t.timestamps
    end
  end

  def self.down
    drop_table :finance_transaction_receipt_records
  end
end
