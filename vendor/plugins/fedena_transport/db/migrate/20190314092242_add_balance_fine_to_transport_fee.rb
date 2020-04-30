class AddBalanceFineToTransportFee < ActiveRecord::Migration
  def self.up
    add_column :transport_fees, :balance_fine, :decimal, :precision => 15, :scale => 2
  end

  def self.down
    remove_column :transport_fees, :balance_fine
  end
end
