class CreateEmployeeSalaryStructureComponents < ActiveRecord::Migration
  def self.up
    create_table :employee_salary_structure_components do |t|
      t.references :employee_salary_structure
      t.references :payroll_category
      t.string :amount
      t.timestamps
    end
  end

  def self.down
    drop_table :employee_salary_structure_components
  end
end
