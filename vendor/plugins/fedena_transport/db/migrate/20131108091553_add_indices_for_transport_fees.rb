class AddIndicesForTransportFees < ActiveRecord::Migration
  def self.up
    add_index :transport_fees, [:receiver_id,:transaction_id],:name => "indices_on_transactions"
    add_index :transport_fees, [:transport_fee_collection_id] ,:name=>"transport_fee_collection_id"
    add_index :transport_fee_collections, [:batch_id]
  end

  def self.down
    remove_index :transport_fees, :name => "indices_on_transactions"
    remove_index :transport_fees,:name=>"transport_fee_collection_id"
    remove_index :transport_fee_collections, [:batch_id]
  end
end
