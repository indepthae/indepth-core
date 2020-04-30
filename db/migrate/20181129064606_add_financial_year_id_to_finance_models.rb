class AddFinancialYearIdToFinanceModels < ActiveRecord::Migration
  def self.up
    add_column :finance_fee_categories, :financial_year_id, :integer
    add_column :finance_fee_collections, :financial_year_id, :integer
    add_column :finance_transaction_ledgers, :financial_year_id, :integer
    add_column :employee_payslips, :financial_year_id, :integer
    add_column :finance_donations, :financial_year_id, :integer

    add_index :finance_fee_categories, :financial_year_id, :name => "index_by_financial_year"
    add_index :finance_fee_collections, :financial_year_id, :name => "index_by_financial_year"
    add_index :finance_transaction_ledgers, :financial_year_id, :name => "index_by_financial_year"
    add_index :employee_payslips, :financial_year_id, :name => "index_by_financial_year"
    add_index :finance_donations, :financial_year_id, :name => "index_by_financial_year"
  end

  def self.down
    remove_index :finance_donations, :name => "index_by_financial_year"
    remove_index :employee_payslips, :name => "index_by_financial_year"
    remove_index :finance_transaction_ledgers, :name => "index_by_financial_year"
    remove_index :finance_fee_collections, :name => "index_by_financial_year"
    remove_index :finance_fee_categories, :name => "index_by_financial_year"

    remove_column :finance_donations, :financial_year_id, :integer
    remove_column :employee_payslips, :financial_year_id, :integer
    remove_column :finance_transaction_ledgers, :financial_year_id, :integer
    remove_column :finance_fee_collections, :financial_year_id, :integer
    remove_column :finance_fee_categories, :financial_year_id, :integer
  end
end
