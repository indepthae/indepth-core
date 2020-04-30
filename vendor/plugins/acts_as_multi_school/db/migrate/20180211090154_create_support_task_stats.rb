class CreateSupportTaskStats < ActiveRecord::Migration
  def self.up
    create_table :support_task_stats do |t|
      t.integer :owner_id
      t.integer :script_id
      t.integer :status
      t.string :task_type
      t.text :params
      t.text :note
      t.text :log
      t.timestamps
    end
  end

  def self.down
    drop_table :support_task_stats
  end
end
