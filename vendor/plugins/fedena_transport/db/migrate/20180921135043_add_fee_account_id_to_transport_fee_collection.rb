class AddFeeAccountIdToTransportFeeCollection < ActiveRecord::Migration
  def self.up
    add_column :transport_fee_collections, :fee_account_id, :integer
  end

  def self.down
    remove_column :transport_fee_collections, :fee_account_id
  end
end
