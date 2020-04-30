class AddSlabIdToInstantFeeDetails < ActiveRecord::Migration
  def self.up
    add_column :instant_fee_details, :slab_id, :integer
  end

  def self.down
    remove_column :instant_fee_details, :slab_id
  end
end
