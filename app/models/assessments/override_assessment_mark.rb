class OverrideAssessmentMark < ActiveRecord::Base
  belongs_to :assessment_group
#  belongs_to :assessment_plan
  belongs_to :course
  
  validates_numericality_of  :maximum_marks,:greater_than => 0
end
