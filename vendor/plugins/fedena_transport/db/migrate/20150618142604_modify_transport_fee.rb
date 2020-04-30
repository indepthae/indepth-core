 class ModifyTransportFee < ActiveRecord::Migration
  def self.up
    rename_column :transport_fees, :batch_id, :groupable_id
    add_column :transport_fees, :groupable_type, :string
  end

  def self.down
    remove_column :transport_fees, :groupable_type
  end
end
