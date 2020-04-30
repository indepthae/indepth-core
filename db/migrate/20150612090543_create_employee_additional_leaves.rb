class CreateEmployeeAdditionalLeaves < ActiveRecord::Migration
  def self.up
    create_table :employee_additional_leaves do |t|
      t.integer :employee_id
      t.integer :employee_leave_type_id
      t.integer :employee_attendance_id
      t.date :attendance_date
      t.string :reason
      t.boolean :is_half_day, :default => false
      t.boolean :is_deductable, :default => false
      t.boolean :is_deducted, :default => false
      t.timestamps
    end
  end

  def self.down
    drop_table :employee_additional_leaves
  end
end

