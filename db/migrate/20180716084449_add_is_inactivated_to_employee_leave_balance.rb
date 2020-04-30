class AddIsInactivatedToEmployeeLeaveBalance < ActiveRecord::Migration
  def self.up
    add_column :employee_leave_balances, :is_inactivated, :boolean
  end

  def self.down
    remove_column :employee_leave_balances, :is_inactivated
  end
end
