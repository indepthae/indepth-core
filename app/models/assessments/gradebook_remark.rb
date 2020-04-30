class GradebookRemark < ActiveRecord::Base
  belongs_to :student
  belongs_to :batch
  belongs_to :reportable, :polymorphic => :true
  belongs_to :remarkable, :polymorphic => :true
  
  REMARK_TYPES = {"RemarkSet" => "General Remarks", "Subject" => "Subject-Wise Remarks"}
  REPORT_TYPES = {"AssessmentGroup" => "Exam", "AssessmentTerm" => "Term", "AssessmentPlan" => "Planner"  }
  
end
