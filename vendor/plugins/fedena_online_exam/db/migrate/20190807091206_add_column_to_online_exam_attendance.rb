class AddColumnToOnlineExamAttendance < ActiveRecord::Migration
  def self.up
    add_column :online_exam_attendances, :is_deleted, :boolean, :default => false
  end

  def self.down
    remove_column :online_exam_attendances, :is_deleted
  end
end
