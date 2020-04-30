class AddBatchIdToTransportFees < ActiveRecord::Migration
  def self.up
    add_column :transport_fees, :batch_id, :integer
  end

  def self.down
    remove_column :transport_fees, :batch_id
  end
end
