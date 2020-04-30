class CreateLeaveGroupEmployees < ActiveRecord::Migration
  def self.up
    create_table :leave_group_employees do |t|
      t.references :leave_group
      t.references :employee
      t.string :employee_type

      t.timestamps
    end
    add_index :leave_group_employees, [:leave_group_id]
    add_index :leave_group_employees, [:employee_id]
  end

  def self.down
    drop_table :leave_group_employees
    remove_index :leave_group_employees, [:leave_group_id]
    remove_index :leave_group_employees, [:employee_id]
  end
end
