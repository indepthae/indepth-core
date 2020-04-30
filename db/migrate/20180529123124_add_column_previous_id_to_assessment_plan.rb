class AddColumnPreviousIdToAssessmentPlan < ActiveRecord::Migration
  def self.up
    add_column :assessment_plans, :previous_id, :integer
  end

  def self.down
    remove_column :assessment_plans, :previous_id
  end
end
