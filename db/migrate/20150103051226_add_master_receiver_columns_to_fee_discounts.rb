class AddMasterReceiverColumnsToFeeDiscounts < ActiveRecord::Migration
  def self.up
    add_column :fee_discounts, :master_receiver_type, :string
    add_column :fee_discounts, :master_receiver_id, :integer
  end

  def self.down
    remove_column :fee_discounts, :master_receiver_id
    remove_column :fee_discounts, :master_receiver_type
  end
end
