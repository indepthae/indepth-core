class AddCourseIdToCourseSubject < ActiveRecord::Migration
  def self.up
    add_column :course_subjects, :course_id, :integer
    add_index  :course_subjects, [:course_id]
  end

  def self.down
    remove_column :course_subjects, :course_id
    remove_index :course_subjects, [:course_id]
  end
end