class AddMasterFeeDiscountIdToInstantFeeDetail < ActiveRecord::Migration
  def self.up
    add_column :instant_fee_details, :master_fee_discount_id, :integer
    add_index :instant_fee_details, :master_fee_discount_id, :name => "index_by_mfd_id"
  end

  def self.down
    remove_index :instant_fee_details, :name => "index_by_mfd_id"
    remove_column :instant_fee_details, :master_fee_discount_id
  end
end
