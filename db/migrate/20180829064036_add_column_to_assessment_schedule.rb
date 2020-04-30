class AddColumnToAssessmentSchedule < ActiveRecord::Migration
  def self.up
    add_column :assessment_schedules, :mark_entry_last_date, :text
  end

  def self.down
    remove_column :assessment_schedules, :mark_entry_last_date
  end
end
