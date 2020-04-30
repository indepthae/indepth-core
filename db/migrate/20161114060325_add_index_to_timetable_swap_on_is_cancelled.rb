class AddIndexToTimetableSwapOnIsCancelled < ActiveRecord::Migration
  def self.up
    add_index :timetable_swaps, :is_cancelled, :name => "index_on_is_cancelled"
  end

  def self.down
    remove_index :timetable_swaps, :is_cancelled, :name => "index_on_is_cancelled"
  end
end
