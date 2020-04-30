class AddLeaveYearIdToEmployeeLeaveBalance < ActiveRecord::Migration
  def self.up
    add_column :employee_leave_balances, :leave_year_id, :integer
  end

  def self.down
    remove_column :employee_leave_balances, :leave_year_id
  end
end
