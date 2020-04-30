class AddMasterFeeParticularIdToHostelFeeCollection < ActiveRecord::Migration
  def self.up
    add_column :hostel_fee_collections, :master_fee_particular_id, :integer
    add_index :hostel_fee_collections, :master_fee_particular_id, :name => "by_master_particular_id"
  end

  def self.down
    remove_index :hostel_fee_collections, :name => "by_master_particular_id"
    remove_column :hostel_fee_collections, :master_fee_particular_id
  end
end
