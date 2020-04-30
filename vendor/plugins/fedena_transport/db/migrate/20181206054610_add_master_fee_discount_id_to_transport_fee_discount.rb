class AddMasterFeeDiscountIdToTransportFeeDiscount < ActiveRecord::Migration
  def self.up
    add_column :transport_fee_discounts, :master_fee_discount_id, :integer
    add_index :transport_fee_discounts, :master_fee_discount_id, :name => "index_by_master_fee_discount"
  end

  def self.down
    remove_index :transport_fee_discounts, :name => "index_by_master_fee_discount"
    remove_column :transport_fee_discounts, :master_fee_discount_id, :integer
  end
end
