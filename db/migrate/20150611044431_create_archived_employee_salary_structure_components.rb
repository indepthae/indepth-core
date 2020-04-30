class CreateArchivedEmployeeSalaryStructureComponents < ActiveRecord::Migration
  def self.up
    create_table :archived_employee_salary_structure_components do |t|
      t.references :archived_employee_salary_structure
      t.references :payroll_category
      t.string :amount
      t.timestamps
    end
  end

  def self.down
    drop_table :archived_employee_salary_structure_components
  end
end
