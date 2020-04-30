class AssessmentAttributeProfile < ActiveRecord::Base
  
  has_many :assessment_attributes
  has_many :assessment_groups
  has_many :attribute_assessments
  has_many :subject_attribute_assessments
  
  accepts_nested_attributes_for :assessment_attributes,:allow_destroy => true, :reject_if=> lambda { |a| a[:name].blank? and a[:maximum_marks].blank? }
  validates_presence_of :maximum_marks, :if => lambda{|aap| aap.assessment_attributes.present?}
  validates_presence_of :name, :display_name
  validates_uniqueness_of :name, :case_sensitive => false
  validates_length_of :description, :maximum => 250
  
  validate :check_attributes
  before_validation :set_maximum_marks
  before_save :check_dependents
  
  FORMULA = {'sum' => 'sum', 'average' => 'average', 'bestof' => 'best_of'}
  
  def set_maximum_marks
    self.maximum_marks = self.maximum_subject_marks if self.maximum_marks.blank?
  end
  
  def validate
    errors.add(:base, :dependencies_exist) if dependencies_present?
  end
  
  def formula_text
    "#{formula.capitalize} of attribute scores"
  end
  
  def attributes_count
    assessment_attributes.length
  end
  
  def dependencies_present?
    assessment_groups.present? or subject_attribute_assessments.present?
  end
    
  def calculate_final_score(marks)
    send("calculate_#{formula}", marks)
  end
    
  def check_attributes
    attributes = assessment_attributes.select{|a| !a.marked_for_destruction?}.group_by{|gr| gr.name.downcase}
    attributes.each do |name, attribute|
      if name.present? and attribute.length > 1
        attribute.each{|gr| gr.errors.add(:name, :taken)}
        errors.add(:base, :dependencies_exist)
      end
    end
  end
  
  def calculate_sum(marks)
    obtained_marks = marks.map{|id, values| values[:mark].to_f}
    max_marks = marks.map{|id, values| values[:max_mark].to_f}
    (obtained_marks.sum/max_marks.sum)*maximum_marks.to_f
  end
  
  def calculate_average(marks)
    converted_marks = marks.map{|id, values| values[:converted_mark].to_f}
    (converted_marks.sum/marks.length)
  end
  
  def calculate_bestof(marks)
    converted_marks = marks.map{|id, values| values[:converted_mark].to_f}
    converted_marks.max
  end
  
  def check_dependents
    assessment_attributes.each do |attribute|
      attribute.mark_for_destruction if attribute.name.blank? and attribute.maximum_marks.blank?
    end
  end
  
  def formula_text
    formula.present? ? t(FORMULA[formula]) : '-' 
  end
  
end
