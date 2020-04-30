class AddBatchIdToCollectionMasterParticularReport < ActiveRecord::Migration
  def self.up
    add_column :collection_master_particular_reports, :batch_id, :integer, :null => false
  end

  def self.down
    remove_column :collection_master_particular_reports, :batch_id
  end
end
