class DerivedAssessmentGroupSetting < ActiveRecord::Base
  belongs_to :derived_assessment_group
  serialize :value,  DerivedAssessmentGroup::Setting if AssessmentGroup.table_exists?
  
  def formula
    self.value.formula
  end
  
  def weightage
    self.value.weightage || {}
  end
  
  def report_settings
    self.value.report_settings || []
  end
  
  def other_settings
    self.value.other_settings || {}
  end
end
