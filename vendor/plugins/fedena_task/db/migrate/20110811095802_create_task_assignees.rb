class CreateTaskAssignees < ActiveRecord::Migration
  def self.up
    create_table :task_assignees do |t|
      t.references :task
      t.integer :assignee_id

      t.timestamps
    end
  end

  def self.down
    drop_table :task_assignees
  end
end
