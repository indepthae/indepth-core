class AddIndexToEmployeeLeave < ActiveRecord::Migration
  def self.up
    add_index :employee_leaves, :employee_id
  end

  def self.down
    remove_index :employee_leaves, :employee_id
  end
end
