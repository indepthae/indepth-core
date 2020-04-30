class AddBatchIdToHostelFees < ActiveRecord::Migration
  def self.up
    add_column :hostel_fees, :batch_id, :integer
  end

  def self.down
    remove_column :hostel_fees, :batch_id
  end
end
