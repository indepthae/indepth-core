class AddColumnToActivityAssessment < ActiveRecord::Migration
  def self.up
    add_column :activity_assessments, :mark_entry_locked, :boolean, :default=>false
    add_column :activity_assessments, :unlocked, :boolean, :default=>false
  end

  def self.down
    remove_column :activity_assessments, :mark_entry_locked
    remove_column :activity_assessments, :unlocked
  end
end
