class CreatePayrollRevisions < ActiveRecord::Migration
  def self.up
    create_table :payroll_revisions do |t|
      t.integer :employee_salary_structure_id
      t.text :payroll_details
      
      t.timestamps
    end
  end

  def self.down
    drop_table :payroll_revisions
  end
end
