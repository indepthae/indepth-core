class CreateLeaveResetLogs < ActiveRecord::Migration
  def self.up
    create_table :leave_reset_logs do |t|
     t.integer :leave_reset_id
     t.integer :employee_id
     t.integer :status
     t.boolean :retry_status, :default => false
     t.text :reason
     t.timestamps
    end
  end

  def self.down
    drop_table :leave_reset_logs
  end
end
