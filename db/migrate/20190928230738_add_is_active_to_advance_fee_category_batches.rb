class AddIsActiveToAdvanceFeeCategoryBatches < ActiveRecord::Migration
  def self.up
  	add_column :advance_fee_category_batches, :is_active, :boolean, :null => false, :default => true
  end

  def self.down
  	remove_column :advance_fee_category_batches, :is_active, :boolean
  end
end
