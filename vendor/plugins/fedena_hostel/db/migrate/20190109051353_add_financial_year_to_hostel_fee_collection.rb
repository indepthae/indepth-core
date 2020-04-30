class AddFinancialYearToHostelFeeCollection < ActiveRecord::Migration
  def self.up
    add_column :hostel_fee_collections, :financial_year_id, :integer
    add_index :hostel_fee_collections, :financial_year_id, :name => 'by_financial_year_id'
  end

  def self.down
    remove_index :hostel_fee_collections, :name => 'by_financial_year_id'
    remove_column :hostel_fee_collections, :financial_year_id
  end
end
