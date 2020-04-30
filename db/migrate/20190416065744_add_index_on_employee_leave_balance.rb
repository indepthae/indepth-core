class AddIndexOnEmployeeLeaveBalance < ActiveRecord::Migration
  def self.up
     add_index :employee_leave_balances, :action, :name => "index_by_action"
  end

  def self.down
     remove_index :employee_leave_balances,  :name => "index_by_action"
  end
end
