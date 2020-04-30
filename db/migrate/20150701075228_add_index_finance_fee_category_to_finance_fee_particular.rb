class AddIndexFinanceFeeCategoryToFinanceFeeParticular < ActiveRecord::Migration
  def self.up
    add_index :finance_fee_particulars, :finance_fee_category_id
    add_index :fee_discounts, :finance_fee_category_id
  end

  def self.down
    remove_index :finance_fee_particulars, :finance_fee_category_id
    remove_index :fee_discounts, :finance_fee_category_id
  end
end
