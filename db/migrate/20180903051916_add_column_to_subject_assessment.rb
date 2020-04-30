class AddColumnToSubjectAssessment < ActiveRecord::Migration
  def self.up
    add_column :subject_assessments, :mark_entry_locked, :boolean, :default=>false
    add_column :subject_assessments, :unlocked, :boolean, :default=>false
  end

  def self.down
    remove_column :subject_assessments, :mark_entry_locked
    remove_column :subject_assessments, :unlocked
  end
end
