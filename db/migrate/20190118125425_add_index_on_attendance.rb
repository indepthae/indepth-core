class AddIndexOnAttendance < ActiveRecord::Migration
   def self.up
    add_index :attendances, :attendance_label_id, :name => "index_by_attendance_label_id"
  end

  def self.down
    remove_index :attendances,  :name => "index_by_attendance_label_id"
  end
end
