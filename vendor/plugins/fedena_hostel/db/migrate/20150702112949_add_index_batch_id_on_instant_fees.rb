class AddIndexBatchIdOnInstantFees < ActiveRecord::Migration
  def self.up
    add_index :hostel_fees, :batch_id
  end

  def self.down
    remove_index :hostel_fees, :batch_id
  end
end
