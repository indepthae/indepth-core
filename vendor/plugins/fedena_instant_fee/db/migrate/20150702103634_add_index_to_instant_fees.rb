class AddIndexToInstantFees < ActiveRecord::Migration
  def self.up
    add_index :instant_fees, [:groupable_id,:groupable_type]
    add_index :instant_fees, [:payee_id,:payee_type]
    add_index :instant_fees, :instant_fee_category_id
  end

  def self.down
    remove_index :instant_fees, [:groupable_id,:groupable_type]
    remove_index :instant_fees, [:payee_id,:payee_type]
    remove_index :instant_fees, :instant_fee_category_id
  end
end
