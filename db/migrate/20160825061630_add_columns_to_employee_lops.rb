class AddColumnsToEmployeeLops < ActiveRecord::Migration
  def self.up
    add_column :employee_lops, :lop_as_deduction, :boolean, :default => true
    add_column :employee_payslips, :deducted_from_categories, :boolean, :default => false
    add_column :employee_payslips, :payroll_revision_id, :integer
    add_column :employee_salary_structures, :latest_revision_id, :integer
    add_column :archived_employee_salary_structures, :latest_revision_id, :integer
  end

  def self.down
    remove_column :employee_lops, :lop_as_deduction
    remove_column :employee_payslips, :deducted_from_categories
    remove_column :employee_payslips, :payroll_revision_id
    remove_column :employee_salary_structures, :latest_revision_id
    remove_column :archived_employee_salary_structures, :latest_revision_id
  end
end
