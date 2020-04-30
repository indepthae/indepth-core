class AddIndexOnSubjectLeave < ActiveRecord::Migration
  def self.up
    add_index :subject_leaves, :attendance_label_id, :name => "index_by_attendance_label_id"
  end

  def self.down
    remove_index :subject_leaves,  :name => "index_by_attendance_label_id"
  end
end
