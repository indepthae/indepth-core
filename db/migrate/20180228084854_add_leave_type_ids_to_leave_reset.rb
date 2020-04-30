class AddLeaveTypeIdsToLeaveReset < ActiveRecord::Migration
  def self.up
    add_column :leave_resets, :leave_type_ids, :text
  end

  def self.down
    remove_column :leave_resets, :leave_type_ids
  end
end
