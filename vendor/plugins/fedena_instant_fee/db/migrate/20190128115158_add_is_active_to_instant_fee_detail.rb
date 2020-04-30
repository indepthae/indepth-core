class AddIsActiveToInstantFeeDetail < ActiveRecord::Migration
  def self.up
    add_column :instant_fee_details, :is_active, :boolean, :default => true
    add_index :instant_fee_details, :is_active, :name => "index_by_is_active"
  end

  def self.down
    remove_index :instant_fee_details, :name => "index_by_is_active"
    remove_column :instant_fee_details, :is_active
  end
end
