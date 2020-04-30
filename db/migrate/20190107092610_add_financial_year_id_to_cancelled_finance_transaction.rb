class AddFinancialYearIdToCancelledFinanceTransaction < ActiveRecord::Migration
  def self.up
    add_column :cancelled_finance_transactions, :financial_year_id, :integer
  end

  def self.down
    remove_column :cancelled_finance_transactions, :financial_year_id
  end
end
