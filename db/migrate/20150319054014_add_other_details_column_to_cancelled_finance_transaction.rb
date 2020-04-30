class AddOtherDetailsColumnToCancelledFinanceTransaction < ActiveRecord::Migration
  def self.up
    add_column :cancelled_finance_transactions, :other_details, :text
    add_column :cancelled_finance_transactions, :finance_transaction_id, :integer
  end

  def self.down
    remove_column :cancelled_finance_transactions, :other_details
    remove_column :cancelled_finance_transactions, :finance_transaction_id
  end
end
