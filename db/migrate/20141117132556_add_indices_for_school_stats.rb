class AddIndicesForSchoolStats < ActiveRecord::Migration
  def self.up
    add_index :archived_students, :batch_id
    add_index :finance_transactions, :batch_id
    add_index :employees, :employee_department_id
    add_index :archived_employees, :employee_department_id
  end

  def self.down
    remove_index :archived_students, :batch_id
    remove_index :finance_transactions, :batch_id
    remove_index :employees, :employee_department_id
    remove_index :archived_employees, :employee_department_id
  end
end
