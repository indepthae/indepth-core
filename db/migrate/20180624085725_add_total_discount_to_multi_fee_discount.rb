class AddTotalDiscountToMultiFeeDiscount < ActiveRecord::Migration
  def self.up
    add_column :multi_fee_discounts, :total_discount, :decimal, :precision => 15, :scale => 4
  end

  def self.down
    remove_column :multi_fee_discounts, :total_discount
  end
end
