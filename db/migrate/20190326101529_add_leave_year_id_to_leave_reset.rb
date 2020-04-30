class AddLeaveYearIdToLeaveReset < ActiveRecord::Migration
  def self.up
    add_column :leave_resets, :leave_year_id, :integer
  end

  def self.down
    remove_column :leave_resets, :leave_year_id
  end
end
