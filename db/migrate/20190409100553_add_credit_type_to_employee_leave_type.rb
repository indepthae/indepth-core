class AddCreditTypeToEmployeeLeaveType < ActiveRecord::Migration
  def self.up
    add_column :employee_leave_types, :credit_type, :string
  end

  def self.down
    remove_column :employee_leave_types, :credit_type
  end
end
