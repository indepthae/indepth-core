class CreateFinanceTransactionLedgers < ActiveRecord::Migration
  def self.up
    create_table :finance_transaction_ledgers do |t|
      t.decimal :amount, :precision => 15, :scale => 4
      t.string :payment_mode
      t.text :payment_note
      t.date :transaction_date
      t.integer :payee_id
      t.string :payee_type
      t.string :transaction_type, :limit => 10
      t.string :receipt_no
      t.string :status, :default => 'ACTIVE' # or 'CANCELLED'

      t.timestamps
    end
  end

  def self.down
    drop_table :finance_transaction_ledgers
  end
end
