class AddFeeCollectionToPayments < ActiveRecord::Migration
  def self.up
    add_column :payments, :fee_collection_id, :integer
    add_column :payments, :fee_collection_type, :string
  end

  def self.down
    remove_column :payments, :fee_collection_id
    remove_column :payments, :fee_collection_type
  end
end
