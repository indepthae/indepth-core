class AddColumnIsActivityToSubjects < ActiveRecord::Migration
  def self.up
    add_column :course_subjects, :is_activity, :boolean, :default => false
    add_column :subjects, :is_activity, :boolean, :default => false
  end

  def self.down
    remove_column :course_subjects, :is_activity
    remove_column :subjects, :is_activity
  end
end
