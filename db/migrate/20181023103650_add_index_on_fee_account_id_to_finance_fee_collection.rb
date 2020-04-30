class AddIndexOnFeeAccountIdToFinanceFeeCollection < ActiveRecord::Migration
  def self.up
    add_index :finance_fee_collections, :fee_account_id, :name => "index_by_fee_account_id"
  end

  def self.down
    remove_index :finance_fee_collections, :fee_account_id, :name => "index_by_fee_account_id"
  end
end
