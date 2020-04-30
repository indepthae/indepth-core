class ChangeFeeDiscountIdAllowNullToFinanceFeeDiscounts < ActiveRecord::Migration
  def self.up
    change_column :finance_fee_discounts, :fee_discount_id, :integer, :null => true
  end

  def self.down
    change_column :finance_fee_discounts, :fee_discount_id, :integer, :null => false
  end
end
