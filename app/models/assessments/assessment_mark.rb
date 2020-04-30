class AssessmentMark < ActiveRecord::Base
  
  attr_accessor :sl_no, :student_name, :student_roll_no, :student_admission_no, :from_import
  
  belongs_to :student
  belongs_to :grade_details, :class_name => "Grade", :foreign_key => "grade_id"
  belongs_to :assessment, :polymorphic => true
  belongs_to :subject_assessment
  belongs_to :attribute_assessment
  belongs_to :activity_assessment
  belongs_to :skill_assessment
  
  before_save :reset_for_absentee
  before_save :check_for_mark_change , :if => :marks_changes
  after_destroy :check_for_mark_change
  
  validates_numericality_of :marks, :greater_than_or_equal_to => 0.0, :allow_blank => true
  validate :check_max_mark_and_min, :if => :from_import
  
  def check_max_mark_and_min
    ass = self.assessment
    if ass.is_a?(AttributeAssessment)
      attr = ass.assessment_attribute
      max = attr.maximum_marks
      self.errors.add(:marks, "#{t('cant_be_more_than_maxmarks')}") if !marks.blank? and (marks > max.to_f)
    elsif ass.is_a?(SkillAssessment)
      skill = ass.subject_skill
      max = skill.maximum_marks
      self.errors.add(:marks, "#{t('cant_be_more_than_maxmarks')}") if !marks.blank? and (marks > max.to_f)
    elsif marks.present?
      self.errors.add(:marks, "#{t('cant_be_more_than_maxmarks')}") if !marks.blank? and (marks > ass.maximum_marks.to_f)
    end
    if self.grade.present? and self.grade_id.nil?
      self.errors.add(:grade, :invalid) unless marks.present?
    end
  end

  def reset_for_absentee
    self.attributes = {:marks => '', :grade => '', :grade_id => ''} if self.is_absent
  end
  
  def check_for_mark_change
    assess = self.assessment
    assess.update_attributes(:submission_status => nil) if assess.submission_status == 2
  end
  
  def marks_changes
    self.marks_changed? or self.grade_changed? or self.grade_id_changed? or self.is_absent_changed?
  end
  
end
