class AddFinancialYearIdToInstantFeeTables < ActiveRecord::Migration
  def self.up
    add_column :instant_fee_categories, :financial_year_id, :integer
    add_column :instant_fees, :financial_year_id, :integer

    add_index :instant_fee_categories, :financial_year_id
    add_index :instant_fees, :financial_year_id
  end

  def self.down
    remove_index :instant_fees, :financial_year_id
    remove_index :instant_fee_categories, :financial_year_id

    remove_column :instant_fees, :financial_year_id, :integer
    remove_column :instant_fee_categories, :financial_year_id
  end
end
