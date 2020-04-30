class AddIndexToPayments < ActiveRecord::Migration
  def self.up
    add_index :payments, :payee_id
    add_index :payments, :payment_id
    add_index :payments, :status
  end

  def self.down
    remove_index :payments, :payee_id
    remove_index :payments, :payment_id
    remove_index :payments, :status
  end

end
