class AddFinancialYearIdToTransportFeeCollection < ActiveRecord::Migration
  def self.up
    add_column :transport_fee_collections, :financial_year_id, :integer
    add_index :transport_fee_collections, :financial_year_id, :name => "index_by_fyid"
  end

  def self.down
    remove_index :transport_fee_collections, :name => "index_by_fyid"
    remove_column :transport_fee_collections, :financial_year_id
  end
end
