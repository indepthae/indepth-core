class RemarkSet < ActiveRecord::Base
  belongs_to :assessment_plan
  has_many :gradebook_remarks, :as => :remarkable, :dependent=>:destroy
  
#  before_validation :check_assessment_report_settings

  TARGET_TYPE = { "AssessmentGroup" => "Exam Report Remark", "AssessmentTerm" => "Term Report Remark", "AssessmentPlan" => "Planner Report Remark" }
  
  
  def check_assessment_report_settings
    general_remark = self.assessment_plan.assessment_report_settings.detect{|ars| ars.setting_key == "GeneralRemarks"}
    ret_val = general_remark.setting_value == "1" ? true : false
    if ret_val
      unless self.name.present?
        errors.add_to_base("Remark name cant be blank")
      end
    end
  end
  
end