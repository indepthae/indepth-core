class CreateRecordBatchAssignments < ActiveRecord::Migration
  def self.up
    create_table :record_batch_assignments do |t|
      t.integer :record_group_id
      t.integer :batch_id
      t.integer :record_assignment_id
      t.timestamps
    end
  end

  def self.down
    drop_table :record_batch_assignments
  end
end
