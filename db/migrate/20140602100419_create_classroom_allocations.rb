class CreateClassroomAllocations < ActiveRecord::Migration
  def self.up
     create_table :classroom_allocations do |t|
      t.string :allocation_type
      t.integer :timetable_id
      t.date :date
      t.timestamps
   end
  end

  def self.down
     drop_table :classroom_allocations
  end
end
