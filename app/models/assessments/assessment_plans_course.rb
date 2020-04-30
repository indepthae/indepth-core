class AssessmentPlansCourse < ActiveRecord::Base
  
  attr_accessor :selected, :name, :batches_count, :disable, :planner_name
  
  belongs_to :course
  belongs_to :assessment_plan
  
  before_destroy :check_plan_dependencies
  
  def check_plan_dependencies
    return false if assessment_plan.has_dependency_for_course(course)
  end
  
end