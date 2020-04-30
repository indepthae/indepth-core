class AddColumnToEmployeePayslips < ActiveRecord::Migration
  def self.up
    add_column :employee_payslips, :employee_details, :text
  end

  def self.down
    remove_column :employee_payslips, :employee_details
  end
end
