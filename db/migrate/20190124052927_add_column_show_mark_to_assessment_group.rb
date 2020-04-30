class AddColumnShowMarkToAssessmentGroup < ActiveRecord::Migration
  def self.up
    add_column :assessment_groups, :hide_marks, :boolean, :default => false
  end

  def self.down
    remove_column :assessment_groups, :hide_marks
  end
end
