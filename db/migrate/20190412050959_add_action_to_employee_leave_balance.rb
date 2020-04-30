class AddActionToEmployeeLeaveBalance < ActiveRecord::Migration
  def self.up
    add_column :employee_leave_balances, :action, :string
  end

  def self.down
    remove_column :employee_leave_balances, :action
  end
end
