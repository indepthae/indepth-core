class AddColumnsToEmployeePayslips < ActiveRecord::Migration
  def self.up
    add_column :employee_payslips, :total_earnings, :string
    add_column :employee_payslips, :total_deductions, :string
  end

  def self.down
    remove_column :employee_payslips, :total_earnings
    remove_column :employee_payslips, :total_deductions
  end
end
