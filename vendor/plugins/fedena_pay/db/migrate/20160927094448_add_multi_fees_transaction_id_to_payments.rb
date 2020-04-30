class AddMultiFeesTransactionIdToPayments < ActiveRecord::Migration
  def self.up
    add_column :payments, :multi_fees_transaction_id, :integer
  end

  def self.down
    remove_column :payments, :multi_fees_transaction_id
  end
end
