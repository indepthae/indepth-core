class CreateGradebookAttendance < ActiveRecord::Migration
  def self.up
    create_table :gradebook_attendances do |t|
      t.references :student
      t.references  :batch
      t.string :linkable_type
      t.integer :linkable_id
      t.integer :total_working_days
      t.integer :total_days_present
      
      t.timestamps
    end
  end

  def self.down
    drop_table :gradebook_attendances
  end
end
