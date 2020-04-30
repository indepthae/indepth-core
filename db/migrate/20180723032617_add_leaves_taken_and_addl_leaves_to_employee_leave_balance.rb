class AddLeavesTakenAndAddlLeavesToEmployeeLeaveBalance < ActiveRecord::Migration
  def self.up
    add_column :employee_leave_balances, :leaves_taken, :decimal, :precision => 5, :scale => 1, :default => 0
    add_column :employee_leave_balances, :additional_leaves, :decimal, :precision => 5, :scale => 1, :default => 0
  end

  def self.down
    remove_column :employee_leave_balances, :additional_leaves
    remove_column :employee_leave_balances, :leaves_taken
  end
end
