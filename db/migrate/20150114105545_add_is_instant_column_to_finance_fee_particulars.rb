class AddIsInstantColumnToFinanceFeeParticulars < ActiveRecord::Migration
  def self.up
    add_column :finance_fee_particulars, :is_instant, :boolean,:default=>false
  end

  def self.down
    remove_column :finance_fee_particulars, :is_instant
  end
end
