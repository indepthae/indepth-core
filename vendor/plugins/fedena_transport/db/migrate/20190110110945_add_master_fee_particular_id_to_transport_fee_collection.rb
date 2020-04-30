class AddMasterFeeParticularIdToTransportFeeCollection < ActiveRecord::Migration
  def self.up
    add_column :transport_fee_collections, :master_fee_particular_id, :integer
    add_index :transport_fee_collections, :master_fee_particular_id, :name => "by_master_particular_id"
  end

  def self.down
    remove_index :transport_fee_collections, :name => "by_master_particular_id"
    remove_column :transport_fee_collections, :master_fee_particular_id
  end
end
