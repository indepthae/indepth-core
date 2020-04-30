class AddGroupableIdAndGroupableTypeInInstantFee < ActiveRecord::Migration
  def self.up
    add_column :instant_fees, :groupable_type, :string
    add_column :instant_fees, :groupable_id, :integer
  end

  def self.down
    remove_column :instant_fees, :groupable_type
    remove_column :instant_fees, :groupable_id
  end
end
