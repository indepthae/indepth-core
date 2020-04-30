class AddMasterReceiverAndFeeTypeToMultiFeeDiscount < ActiveRecord::Migration
  def self.up
    add_column :multi_fee_discounts, :master_receiver_type, :string, :null => false
    add_column :multi_fee_discounts, :master_receiver_id, :integer, :null => false
    add_column :multi_fee_discounts, :fee_type, :string
    add_column :multi_fee_discounts, :fee_id, :integer
    add_index :multi_fee_discounts, [:master_receiver_type, :master_receiver_id], :name => "by_master_receiver"
    add_index :multi_fee_discounts, [:fee_type, :fee_id], :name => "by_fee"
  end

  def self.down
    remove_index :multi_fee_discounts, :name => "by_fee"
    remove_index :multi_fee_discounts, :name => "by_master_receiver"
    remove_column :multi_fee_discounts, :fee_id, :integer
    remove_column :multi_fee_discounts, :fee_type, :string
    remove_column :multi_fee_discounts, :master_receiver_id
    remove_column :multi_fee_discounts, :master_receiver_type
  end
end
