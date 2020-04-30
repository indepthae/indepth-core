class AddDiscountModeToFinanceFeeCollections < ActiveRecord::Migration
  def self.up
    add_column :finance_fee_collections, :discount_mode, :string, :default => "OLD_DISCOUNT"
  end

  def self.down
    remove_column :finance_fee_collections, :discount_mode
  end
end
