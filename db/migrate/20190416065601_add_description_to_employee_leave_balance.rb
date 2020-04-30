class AddDescriptionToEmployeeLeaveBalance < ActiveRecord::Migration
  def self.up
    add_column :employee_leave_balances, :description, :string
  end

  def self.down
    remove_column :employee_leave_balances, :description
  end
end
