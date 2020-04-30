class CreatePayments < ActiveRecord::Migration
  def self.up
    create_table   :payments do |t|
      t.string     :payee_type
      t.integer    :payee_id
      t.string     :payment_type
      t.integer    :payment_id
      t.text       :gateway_response
      t.references :finance_transaction
      t.integer    :school_id

      t.timestamps
    end
  end

  def self.down
    drop_table :payments
  end
end
