class CreatePaytmPaymentRecords < ActiveRecord::Migration
  def self.up
    create_table :paytm_payment_records do |t|
      t.references :transaction_ledger
      t.integer    :order_id
      t.integer    :item_id
      t.decimal    :amount, :precision => 15, :scale => 4
      t.integer    :school_id
      t.timestamps
    end
  end

  def self.down
    drop_table :paytm_payment_records
  end
end
