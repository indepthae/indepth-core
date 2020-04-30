class AddLeaveYearIdToLeaveResetLog < ActiveRecord::Migration
  def self.up
    add_column :leave_reset_logs, :leave_year_id, :integer
  end

  def self.down
    remove_column :leave_reset_logs, :leave_year_id
  end
end
