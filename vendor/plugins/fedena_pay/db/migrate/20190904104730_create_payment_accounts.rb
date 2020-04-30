class CreatePaymentAccounts < ActiveRecord::Migration
  def self.up
    create_table :payment_accounts do |t|
      t.integer :custom_gateway_id
      t.integer :collection_id
      t.string :collection_type
      t.text :account_params
      t.integer :school_id

      t.timestamps
    end
  end

  def self.down
    drop_table :payment_accounts
  end
end
