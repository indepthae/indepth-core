class CreateMultiFeesTransactions < ActiveRecord::Migration
  def self.up
    create_table :multi_fees_transactions do |t|
      t.decimal :amount, :precision =>15, :scale => 2
      t.string :payment_mode
      t.text :payment_note
      t.date :transaction_date
      t.references :student

      t.timestamps
    end
  end

  def self.down
    drop_table :multi_fees_transactions
  end
end
