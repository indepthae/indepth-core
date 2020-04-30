class AddIndexToReceiptNumberSetOnName < ActiveRecord::Migration
  def self.up
    add_index :receipt_number_sets, [:name], :name => "index_by_name"    
  end

  def self.down
    remove_index :receipt_number_sets, :name => "index_by_name"    
  end
end
