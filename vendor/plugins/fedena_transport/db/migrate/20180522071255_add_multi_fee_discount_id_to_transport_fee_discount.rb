class AddMultiFeeDiscountIdToTransportFeeDiscount < ActiveRecord::Migration
  def self.up
    add_column :transport_fee_discounts, :multi_fee_discount_id, :integer
    add_index :transport_fee_discounts, :multi_fee_discount_id, :name => "by_multi_fee_discount"
  end

  def self.down
    remove_index :transport_fee_discounts, :name => "by_multi_fee_discount"
    remove_column :transport_fee_discounts, :multi_fee_discount_id
  end
end
