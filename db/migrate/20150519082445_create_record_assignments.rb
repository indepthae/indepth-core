class CreateRecordAssignments < ActiveRecord::Migration
  def self.up
    create_table :record_assignments do |t|
      t.integer :course_id
      t.integer :record_group_id
      t.integer :priority
      t.boolean :add_for_future,:default=>false
      t.timestamps
    end
  end

  def self.down
    drop_table :record_assignments
  end
end
