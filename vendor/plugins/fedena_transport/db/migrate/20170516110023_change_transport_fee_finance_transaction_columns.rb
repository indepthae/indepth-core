class ChangeTransportFeeFinanceTransactionColumns < ActiveRecord::Migration
  def self.up
    change_column :transport_fee_finance_transactions, :transaction_balance,  :decimal, :precision=>15, :scale=>4
    change_column :transport_fee_finance_transactions, :transaction_amount,  :decimal, :precision=>15, :scale=>4
  end

  def self.down
  end
end
