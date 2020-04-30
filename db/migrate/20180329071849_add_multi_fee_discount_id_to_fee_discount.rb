class AddMultiFeeDiscountIdToFeeDiscount < ActiveRecord::Migration
  def self.up
    add_column :fee_discounts, :multi_fee_discount_id, :integer
    add_index :fee_discounts, :multi_fee_discount_id, :name => "index_by_multi_fee_discount"
  end

  def self.down
    remove_column :fee_discounts, :multi_fee_discount_id
    remove_index :fee_discounts, :name => "index_by_multi_fee_discount"
  end
end
