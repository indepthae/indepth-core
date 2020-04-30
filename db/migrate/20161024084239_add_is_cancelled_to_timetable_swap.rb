class AddIsCancelledToTimetableSwap < ActiveRecord::Migration
  def self.up
    add_column :timetable_swaps, :is_cancelled, :boolean, :default => false
  end

  def self.down
    remove_column :timetable_swaps, :is_cancelled
  end
end
