class AddFineIdToTransportFeeCollection < ActiveRecord::Migration
  def self.up
    add_column :transport_fee_collections, :fine_id, :integer
  end

  def self.down
    remove_column :transport_fee_collections, :fine_id
  end
end
