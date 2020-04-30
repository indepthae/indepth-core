class AddIsActiveColumnToTransportFee < ActiveRecord::Migration
  def self.up
    add_column :transport_fees,:is_active, :boolean,:default=>true
  end

  def self.down
    remove_column :transport_fees,:is_active, :boolean
  end
end


