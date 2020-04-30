class AddIndicesToFinanceCategoryReceiptSet < ActiveRecord::Migration
  def self.up
    add_index :finance_category_receipt_sets, [:category_id, :category_type], :name => "index_by_category"
    add_index :finance_category_receipt_sets, :receipt_number_set_id, :name => "index_by_receipt_number_set"    
  end

  def self.down
    remove_index :finance_category_receipt_sets, :receipt_number_set_id, :name => "index_by_receipt_number_set"    
    remove_index :finance_category_receipt_sets, [:category_id, :category_type], :name => "index_by_category"
  end
end
