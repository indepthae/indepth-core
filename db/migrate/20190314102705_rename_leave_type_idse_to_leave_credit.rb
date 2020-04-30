class RenameLeaveTypeIdseToLeaveCredit < ActiveRecord::Migration
  def self.up
    rename_column :leave_credits, :leave_Type_ids , :leave_type_ids
  end

  def self.down
    rename_column :leave_credits, :leave_type_ids, :leave_Type_ids
  end
end
