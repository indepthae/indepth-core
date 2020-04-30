class AddIndexesToPaymentModels < ActiveRecord::Migration
  def self.up
    add_index :finance_payments, :payment_id, :name => "by_payment_id"
    add_index :payments, :created_at, :name => "by_creation"
  end

  def self.down
    remove_index :payments, :created_at, :name => "by_creation"
    remove_index :finance_payments, :payment_id, :name => "by_payment_id"
  end
end
