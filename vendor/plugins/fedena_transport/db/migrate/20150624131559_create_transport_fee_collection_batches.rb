class CreateTransportFeeCollectionBatches < ActiveRecord::Migration
  def self.up
   create_table :transport_fee_collection_batches do |t|
      t.references :transport_fee_collection
      t.integer    :batch_id
      t.timestamps
    end
  end

  def self.down
    drop_table :transport_fee_collection_batches
  end
end
