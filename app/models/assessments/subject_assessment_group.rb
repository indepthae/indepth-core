class SubjectAssessmentGroup < AssessmentGroup
  
  validates_presence_of :assessment_attribute_profile_id, :if => :check_attribute
  validates_presence_of  :grade_set_id, :if => Proc.new { |p| ([2, 3].include? p.scoring_type.to_i) }
  validates_presence_of  :maximum_marks, :if => Proc.new { |p| ([1, 3].include? p.scoring_type.to_i) }
  validates_presence_of  :minimum_marks, :if => Proc.new { |p| (p.scoring_type.to_i == 1) }
  
  before_save :update_attr
  before_save :update_score_values
  
  def check_attribute
    (!is_single_mark_entry? and is_attribute_same?)
  end
  
  def update_attr
    self.assessment_activity_profile_id = nil
    if is_single_mark_entry
      self.is_attribute_same = nil
      self.assessment_attribute_profile_id = nil
    elsif !is_attribute_same
      self.assessment_attribute_profile_id = nil
    end
  end
  
  def update_score_values
    case scoring_type
    when 1
      self.grade_set_id = nil
    when 2
      self.maximum_marks = nil
      self.minimum_marks = nil
    when 3
      self.minimum_marks = nil
    end
  end
  
  def self.with_mark_scoring(plan,term)
    if term.present?
      all(:conditions=>["parent_id = ? AND parent_type = ? AND (scoring_type = ? OR scoring_type = ?)",term.id,'AssessmentTerm',1,3])
    else
      all(:conditions=>["assessment_plan_id = ? and parent_type = ? AND (scoring_type = ? OR scoring_type = ?)",plan.id,'AssessmentPlan',1,3])
    end
  end
  
  def self.without_mark_scoring(plan,term)
    if term.present?
      all(:conditions=>["parent_id = ? AND parent_type = ?",term.id,'AssessmentTerm'])
    else
      all(:conditions=>["assessment_plan_id = ? and parent_type = ?",plan.id,'AssessmentPlan'])
    end
  end
  
end
