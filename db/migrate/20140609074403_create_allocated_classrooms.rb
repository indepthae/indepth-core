class CreateAllocatedClassrooms < ActiveRecord::Migration
  def self.up
   create_table :allocated_classrooms do |t|
    t.integer :classroom_allocation_id
    t.integer :classroom_id
    t.integer :subject_id
    t.integer :timetable_entry_id
    t.date :date
    t.boolean :is_deleted, :default => false
    t.timestamps
   end
  end

  def self.down
     drop_table :allocated_classrooms
  end
end
