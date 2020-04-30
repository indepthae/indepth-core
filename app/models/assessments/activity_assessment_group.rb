class ActivityAssessmentGroup < AssessmentGroup
  
  validates_presence_of :assessment_activity_profile_id, :grade_set_id
  before_save :update_attr
  before_validation :remove_override_marks
  
  def update_attr
    self.is_single_mark_entry = nil
    self.is_attribute_same = nil
    self.assessment_attribute_profile_id = nil
    self.scoring_type = nil
    self.maximum_marks = nil
    self.minimum_marks = nil
  end
  
  def remove_override_marks
    self.override_assessment_marks.each{|osm| osm.mark_for_destruction}
  end
  
  def activity_groups
    [self]
  end
  
   def self.fetch_all_assessments(plan, term) 
    if term.present?
      all(:conditions=>{:parent_id => term.id,:parent_type => 'AssessmentTerm', :is_final_term => false})
    else
      all(:conditions=>{:assessment_plan_id => plan.id , :parent_type => 'AssessmentPlan', :is_final_term => false})
    end
  end
  

end
