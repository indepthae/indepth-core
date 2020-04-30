class CreateFinancePayments < ActiveRecord::Migration
  def self.up
    create_table   :finance_payments do |t|
      t.string     :fee_payment_type
      t.integer    :fee_payment_id
      t.references :finance_transaction
      t.references :payment
      t.string     :collection_type
      t.integer    :collection_id
      t.integer    :school_id
      t.timestamps
    end
  end

  def self.down
    drop_table :finance_payments
  end
end
