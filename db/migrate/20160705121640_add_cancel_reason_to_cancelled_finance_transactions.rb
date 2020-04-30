class AddCancelReasonToCancelledFinanceTransactions < ActiveRecord::Migration
  def self.up
    add_column :cancelled_finance_transactions, :cancel_reason, :text
  end

  def self.down
    remove_column :cancelled_finance_transactions, :cancel_reason
  end
end
