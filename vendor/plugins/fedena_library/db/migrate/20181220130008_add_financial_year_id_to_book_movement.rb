class AddFinancialYearIdToBookMovement < ActiveRecord::Migration
  def self.up
    add_column :book_movements, :financial_year_id, :integer
    add_index :book_movements, :financial_year_id, :name => "index_by_fyid"
  end

  def self.down
    remove_index :book_movements, :name => "index_by_fyid"
    remove_column :book_movements, :financial_year_id
  end
end
