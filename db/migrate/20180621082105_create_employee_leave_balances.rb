class CreateEmployeeLeaveBalances < ActiveRecord::Migration
  def self.up
    create_table :employee_leave_balances do |t|
      t.references :employee
      t.references :employee_leave_type
      t.decimal    :leave_balance ,:precision => 5, :scale => 1, :default => 0
      t.date       :reset_date
      t.decimal    :leaves_added, :precision => 5, :scale => 1, :default => 0
      
      t.references :school
      
      t.timestamps
    end
  end

  def self.down
    drop_table :employee_leave_balances
  end
end
