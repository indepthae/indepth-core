class AddTaxFieldsToCancelledFinanceTransactions < ActiveRecord::Migration
  def self.up
    add_column :cancelled_finance_transactions, :tax_amount, :decimal, :precision => 15, :scale => 4, :default => 0
    add_column :cancelled_finance_transactions, :tax_included, :boolean, :default => false
  end

  def self.down
    remove_column :cancelled_finance_transactions, :tax_included
    remove_column :cancelled_finance_transactions, :tax_amount
  end
end
