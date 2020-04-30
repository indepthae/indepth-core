class SubjectSkill < ActiveRecord::Base
  belongs_to :subject_skill_set
  belongs_to :skill, :class_name=>"SubjectSkill", :foreign_key=>"higher_skill_id"
  has_many :sub_skills, :class_name=>"SubjectSkill", :foreign_key=>"higher_skill_id", :dependent => :destroy
  accepts_nested_attributes_for :sub_skills,:allow_destroy => true, :reject_if=> lambda { |a| a[:name].blank? }
  has_many :skill_assessments
  named_scope :skills ,:conditions => "higher_skill_id is NULL"
  before_save :reset_values
  validates_numericality_of :maximum_marks, :greater_than => 0, :if => Proc.new {|aa| aa.maximum_marks.present?}
  before_save :handle_formula, :if => Proc.new {|ss| !ss.new_record? and ss.calculate_final_changed? }
  
  def validate
    if self.calculate_final and self.maximum_marks.blank?
      self.errors.add(:maximum_marks, "#{t('cant_be_blank_for_calculating_final')}") 
    end
  end
  
  def handle_formula
    if calculate_final and formula.blank?
      self.formula = 'sum'
    elsif !calculate_final
      self.formula = nil
    end
  end
  
  def locked_from_changing_calculation_mode(set)
    higher_skill_id.nil? and set.calculate_final
  end
  
  def reset_values
    if self.maximum_marks_changed? or self.name_changed?
      if (subject_skill_set.present? and subject_skill_set.exam_dependencies_present? ) or (skill.present? and skill.subject_skill_set.exam_dependencies_present?) 
        self.maximum_marks = self.maximum_marks_was
        self.name = self.name_was
      end
    end
  end
  
  def dependencies_present?
    skill_assessments.present?
  end
  
  def formula_text
    formula.present? ? "#{formula.capitalize} of sub skills scores" : '-'
  end
  
  def is_activity?
    false #Fallback method for using report generation methods
  end
  
  def parent_name_and_type(subject = nil)
    if higher_skill_id.present?
      [skill.name, 'SubjectSkill', higher_skill_id]
    elsif subject.present?
      [subject.name, 'Subject', subject.id]
    end
  end
end
