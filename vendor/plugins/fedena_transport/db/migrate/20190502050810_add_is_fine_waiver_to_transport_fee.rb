class AddIsFineWaiverToTransportFee < ActiveRecord::Migration
  def self.up
    add_column :transport_fees, :is_fine_waiver, :boolean, :default => false
  end

  def self.down
    remove_column :transport_fees, :is_fine_waiver, :boolean
  end
end
