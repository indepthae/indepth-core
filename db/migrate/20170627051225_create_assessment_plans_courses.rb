class CreateAssessmentPlansCourses < ActiveRecord::Migration
  def self.up
    create_table :assessment_plans_courses do |t|
      t.references :assessment_plan
      t.references :course
      t.timestamps
    end
  end

  def self.down
    drop_table :assessment_plans_courses
  end
end
