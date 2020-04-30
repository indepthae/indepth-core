class AddIsActiveToTransportTransactionDiscount < ActiveRecord::Migration
  def self.up
    add_column :transport_transaction_discounts, :is_active, :boolean, :default => true

    add_index :transport_transaction_discounts, :is_active, :name => "index_by_active"
  end

  def self.down
    remove_index :transport_transaction_discounts, :name => "index_by_active"

    remove_column :transport_transaction_discounts, :is_active
  end
end
