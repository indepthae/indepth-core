class AddingFieldsToTransportFeeDiscounts < ActiveRecord::Migration
  def self.up
    add_column :transport_fee_discounts, :finance_transaction_id, :integer
  end

  def self.down
    remove_column :transport_fee_discounts, :finance_transaction_id
  end
end
