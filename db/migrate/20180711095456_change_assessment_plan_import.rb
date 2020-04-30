class ChangeAssessmentPlanImport < ActiveRecord::Migration
  def self.up
    change_column :assessment_plan_imports, :last_error, :text
  end

  def self.down
  end
end
