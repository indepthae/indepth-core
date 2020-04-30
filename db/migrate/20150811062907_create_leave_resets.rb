class CreateLeaveResets < ActiveRecord::Migration
  def self.up
    create_table :leave_resets do |t|
      t.date :reset_date
      t.integer :reset_type
      t.string :reset_remark
      t.integer :resetted_by
      t.integer :status
      t.integer :reset_value
      t.integer :employee_count
      t.timestamps
    end
  end

  def self.down
    drop_table :leave_resets
  end
end
