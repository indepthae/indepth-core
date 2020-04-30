class AddFeeAccountIdToFinanceFeeCollection < ActiveRecord::Migration
  def self.up
    add_column :finance_fee_collections, :fee_account_id, :integer
  end

  def self.down
    remove_column :finance_fee_collections, :fee_account_id
  end
end
