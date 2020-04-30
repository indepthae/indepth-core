class CreateEmployeePayslipCategories < ActiveRecord::Migration
  def self.up
    create_table :employee_payslip_categories do |t|
      t.references :employee_payslip
      t.references :payroll_category
      t.string :amount
      t.timestamps
    end
  end

  def self.down
    drop_table :employee_payslip_categories
  end
end
