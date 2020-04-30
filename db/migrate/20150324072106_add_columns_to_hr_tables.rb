class AddColumnsToHrTables < ActiveRecord::Migration
  def self.up
    add_column :payroll_categories,  :code, :string
    add_column :payroll_categories, :dependant_categories, :text
    add_column :employee_salary_structures,  :gross_salary, :string
    add_column :employee_salary_structures,  :net_pay, :string
    add_column :employee_salary_structures,  :payroll_group_id, :integer
    add_column :employee_salary_structures,  :revision_number, :integer
    add_column :archived_employee_salary_structures,  :gross_salary, :string
    add_column :archived_employee_salary_structures,  :net_pay, :string
    add_column :archived_employee_salary_structures,  :revision_number, :integer
    add_column :archived_employee_salary_structures,  :payroll_group_id, :integer
    add_column :individual_payslip_categories, :employee_payslip_id, :integer
  end

  def self.down
    remove_column :payroll_categories, :code
    remove_column :payroll_categories, :dependant_categories
    remove_column :employee_salary_structures,  :gross_salary
    remove_column :employee_salary_structures,  :net_pay
    remove_column :employee_salary_structures,  :payroll_group_id
    remove_column :employee_salary_structures,  :revision_number
    remove_column :archived_employee_salary_structures,  :gross_salary
    remove_column :archived_employee_salary_structures,  :net_pay
    remove_column :archived_employee_salary_structures,  :revision_number
    remove_column :archived_employee_salary_structures,  :payroll_group_id
    remove_column :individual_payslip_categories, :employee_payslip_id
  end
end
