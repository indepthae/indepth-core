class AddFinancialYearIdToFinanceTransaction < ActiveRecord::Migration
  def self.up
    add_column :finance_transactions, :financial_year_id, :integer
    add_index :finance_transactions, :financial_year_id, :name => 'by_fy_id'
  end

  def self.down
    remove_index :finance_transactions, :financial_year_id, :name => 'by_fy_id'
    remove_column :finance_transactions, :financial_year_id
  end
end
