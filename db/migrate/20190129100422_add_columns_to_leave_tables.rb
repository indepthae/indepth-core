class AddColumnsToLeaveTables < ActiveRecord::Migration
  def self.up
    add_column :employee_leave_types, :credit_frequency, :integer
    add_column :employee_leave_types, :days_count, :integer
    add_column :employee_leaves, :credited_at, :date
    add_column :employee_leaves, :mark_for_credit, :boolean, :default => false
    add_column :employee_leaves, :mark_for_remove, :boolean, :default => false
    add_column :leave_groups, :updating_status, :integer
  end

  def self.down
    remove_column :employee_leave_types, :credit_frequency, :integer
    remove_column :employee_leave_types, :days_count, :integer
    remove_column :employee_leaves, :credited_at, :date
    remove_column :employee_leaves, :mark_for_credit, :boolean
    remove_column :employee_leaves, :mark_for_remove, :boolean
    remove_column :leave_groups, :updating_status, :integer
  end
end
