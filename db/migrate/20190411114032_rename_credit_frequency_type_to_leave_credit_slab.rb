class RenameCreditFrequencyTypeToLeaveCreditSlab < ActiveRecord::Migration
  def self.up
    rename_column :leave_credit_slabs, :credit_frequency_type , :label_order
  end

  def self.down
    rename_column :leave_credit_slabs, :label_order, :credit_frequency_type
  end
end
