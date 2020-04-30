class AddAttendanceLabelIdToSubjectLeave < ActiveRecord::Migration
  def self.up
    add_column :subject_leaves, :attendance_label_id, :integer
  end

  def self.down
    remove_column :subject_leaves, :attendance_label_id
  end
end
