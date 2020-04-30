class AddIsInstantColumnToFeeDiscounts < ActiveRecord::Migration
  def self.up
    add_column :fee_discounts, :is_instant, :boolean,:default=>false
  end

  def self.down
    remove_column :fee_discounts, :is_instant
  end
end
