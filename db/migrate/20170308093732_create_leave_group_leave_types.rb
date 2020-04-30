class CreateLeaveGroupLeaveTypes < ActiveRecord::Migration
  def self.up
    create_table :leave_group_leave_types do |t|
      t.references :leave_group
      t.references :employee_leave_type
      t.decimal :leave_count, :precision => 7, :scale => 2
      
      t.timestamps
    end
    add_index :leave_group_leave_types, [:leave_group_id]
    add_index :leave_group_leave_types, [:employee_leave_type_id]
  end

  def self.down
    drop_table :leave_group_leave_types
    remove_index :leave_group_leave_types, [:leave_group_id]
    remove_index :leave_group_leave_types, [:employee_leave_type_id]
  end
end
