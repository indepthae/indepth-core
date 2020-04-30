class AddColumnToAssessmentGroup < ActiveRecord::Migration
  def self.up
    add_column :assessment_groups, :consider_attendance, :boolean, :default=>false
  end

  def self.down
    remove_column :assessment_groups, :consider_attendance
  end
end
