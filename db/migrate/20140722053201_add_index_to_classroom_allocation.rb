class AddIndexToClassroomAllocation < ActiveRecord::Migration
  def self.up
    add_index :classrooms, [:building_id]
    add_index :classroom_allocations, [:timetable_id]
    add_index :allocated_classrooms, [:timetable_entry_id, :subject_id, :classroom_allocation_id, :classroom_id], :name => :index_by_fields
  end

  def self.down
    remove_index :classrooms, [:building_id]
    remove_index :classroom_allocations, [:timetable_id]
    remove_index :allocated_classrooms, [:timetable_entry_id, :subject_id, :classroom_allocation_id, :classroom_id], :name => :index_by_fields
  end
end
