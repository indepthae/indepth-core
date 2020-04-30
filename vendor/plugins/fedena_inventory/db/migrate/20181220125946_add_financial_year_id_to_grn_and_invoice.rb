class AddFinancialYearIdToGrnAndInvoice < ActiveRecord::Migration
  def self.up
    add_column :grns, :financial_year_id, :integer
    add_column :invoices, :financial_year_id, :integer
    add_index :grns, :financial_year_id, :name => "index_by_fyid"
    add_index :invoices, :financial_year_id, :name => "index_by_fyid"
  end

  def self.down
    remove_index :invoices, :name => "index_by_fyid"
    remove_index :grns, :name => "index_by_fyid"
    remove_column :invoices, :financial_year_id
    remove_column :grns, :financial_year_id
  end
end
