class AlterColumnsForHr < ActiveRecord::Migration
  def self.up

    #apply_leaves
    rename_column :apply_leaves, :employee_leave_types_id, :employee_leave_type_id
    
    #employee_leave_types
    add_column :employee_leave_types, :lop_enabled, :boolean, :default => false
    add_column :employee_leave_types, :max_carry_forward_leaves, :string
    add_column :employee_leave_types, :carry_forward_type, :integer
    add_column :employee_leave_types, :reset_date , :date
    add_column :employee_leave_types, :creation_status, :integer, :default => 1
   
    rename_column :employee_leave_types, :status, :is_active
    change_column :employee_leave_types, :is_active,:boolean, :default => 1
    change_column :employee_leave_types, :carry_forward, :boolean, :default => 0
    EmployeeLeaveType.update_all("creation_status= 2,reset_date = date(created_at)")
    EmployeeLeaveType.update_all("carry_forward_type = 1", "carry_forward = true")

    #employee leaves
    add_column :employee_leaves,:additional_leaves ,:decimal ,:precision => 5, :scale => 1, :default => 0
    rename_column :employee_leaves, :reset_date, :reseted_at
    add_column :employee_leaves, :reset_date, :date
    EmployeeLeave.update_all("reset_date = date(reseted_at)")


    #employee attendance
    add_column :employee_attendances, :apply_leave_id, :integer
    add_column :employee_attendances, :employee_leave_id, :integer
    
    #employee
    add_column :employees ,:last_reset_date,:date

    #archived employee
    add_column :archived_employees ,:last_reset_date,:date
    add_column :archived_employees, :date_of_leaving, :date
  end

  def self.down
    remove_column :employee_leave_types, :lop_enabled
    remove_column :employee_leave_types, :max_carry_forward_leaves
    remove_column :employee_leave_types, :carry_forward_type
    remove_column :employee_leave_types, :reset_date
    remove_column :employee_leave_types, :creation_status

    remove_column :employee_attendances, :apply_leave_id
    remove_column :employee_attendances, :employee_leave_id

    remove_column :employee_leaves, :reseted_at

    remove_column :employees ,:last_reset_date

    remove_column :archived_employees ,:last_reset_date
    remove_column :archived_employees, :date_of_leaving
  end
end
