class AddColumnsToEmployeeLeaves < ActiveRecord::Migration
  def self.up
    add_column :employee_leaves, :leave_group_id, :integer
    add_column :employee_leaves, :is_active, :boolean, :default => true
    add_column :employee_leaves, :is_additional, :boolean, :default => false
    add_index :employee_leaves, [:leave_group_id]
  end

  def self.down
    remove_column :employee_leaves, :leave_group_id
    remove_column :employee_leaves, :is_active
    remove_column :employee_leaves, :is_additional
    remove_index :employee_leaves, [:leave_group_id]
  end
end
