class AddLeaveDetailsToEmployeePayslips < ActiveRecord::Migration
  def self.up
    add_column :employee_payslips, :leave_details, :text
  end

  def self.down
    remove_column :employee_payslips, :leave_details
  end
end
