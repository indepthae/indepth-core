class CreateLeaveCreditLogs < ActiveRecord::Migration
  def self.up
    create_table :leave_credit_logs do |t|
      t.integer :leave_credit_id
      t.integer :employee_id
      t.integer :status
      t.integer :retry_status
      t.string :reason

      t.timestamps
    end
  end

  def self.down
    drop_table :leave_credit_logs
  end
end
