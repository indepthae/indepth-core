class AddBatchIdToAdvanceFeeCollections < ActiveRecord::Migration
  def self.up
    add_column :advance_fee_collections, :batch_id, :integer, :null => true, :default => nil
  end

  def self.down
    remove_column :advance_fee_collections, :batch_id, :integer
  end
end
