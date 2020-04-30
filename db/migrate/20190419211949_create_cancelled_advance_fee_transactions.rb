class CreateCancelledAdvanceFeeTransactions < ActiveRecord::Migration
  def self.up
    create_table :cancelled_advance_fee_transactions do |t|
      t.decimal :fees_paid, :precision =>15, :scale => 2
      t.string :payment_mode
      t.date :date_of_advance_fee_payment
      t.string :reference_no, :default => nil
      t.string :payment_note, :default => nil
      t.string :bank_name, :default => nil
      t.date :cheque_date, :default => nil
      t.string :reason_for_cancel, :default => nil
      t.string :transaction_data, :limit => 1221
      t.references :user
      t.references :advance_fee_category
      t.references :student
      t.references :advance_fee_collection
      t.timestamps
    end
  end

  def self.down
    drop_table :cancelled_advance_fee_transactions
  end
end
