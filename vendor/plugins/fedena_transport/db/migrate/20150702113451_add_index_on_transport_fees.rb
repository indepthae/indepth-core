class AddIndexOnTransportFees < ActiveRecord::Migration
  def self.up
    add_index :transport_fees, [:groupable_id,:groupable_type]
    add_index :transport_fees, [:receiver_id,:receiver_type]
  end

  def self.down
    remove_index :transport_fees, [:groupable_id,:groupable_type]
    remove_index :transport_fees, [:receiver_id,:receiver_type]
  end
end
