class AddIsPaidToTransportFee < ActiveRecord::Migration
  def self.up
    add_column :transport_fees, :is_paid, :boolean, :default => false
  end

  def self.down
    remove_column :transport_fees, :is_paid
  end
end
