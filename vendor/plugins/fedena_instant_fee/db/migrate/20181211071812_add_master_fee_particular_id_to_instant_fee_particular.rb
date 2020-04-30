class AddMasterFeeParticularIdToInstantFeeParticular < ActiveRecord::Migration
  def self.up
    add_column :instant_fee_particulars, :master_fee_particular_id, :integer
    add_index :instant_fee_particulars, :master_fee_particular_id, :name => "index_by_mfd_id"
  end

  def self.down
    remove_index :instant_fee_particulars, :name => "index_by_mfd_id"
    remove_column :instant_fee_particulars, :master_fee_particular_id
  end
end
