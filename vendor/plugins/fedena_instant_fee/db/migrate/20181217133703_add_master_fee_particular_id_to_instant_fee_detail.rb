class AddMasterFeeParticularIdToInstantFeeDetail < ActiveRecord::Migration
  def self.up
    add_column :instant_fee_details, :master_fee_particular_id, :integer
    add_index :instant_fee_details, :master_fee_particular_id, :name => "index_by_mfp_id"
  end

  def self.down
    remove_index :instant_fee_details, :master_fee_particular_id, :name => "index_by_mfp_id"
    remove_column :instant_fee_details, :master_fee_particular_id
  end
end
