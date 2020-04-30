class CourseSubject < ActiveRecord::Base
  belongs_to :parent, :polymorphic => true
  belongs_to :subject_skill_set
  belongs_to :course
  has_many   :subjects
  accepts_nested_attributes_for :subjects,:allow_destroy => true, :reject_if => lambda { |l| l[:selected] == "0" }
  before_validation :set_subject_attributes
  validates_presence_of :name, :max_weekly_classes, :code
  validates_numericality_of :max_weekly_classes, :allow_nil => false, :greater_than_or_equal_to => 1
  validates_numericality_of :amount,:allow_nil => true
  validates_presence_of :credit_hours, :if=>:check_grade_type
  validates_uniqueness_of :code, :case_sensitive => false, :scope=>[:course_id,:is_deleted] ,:if=> 'is_deleted == false'
  before_save :reset_skill_set
  default_scope :order=>'priority ASC'
  after_save  :sync_priority, :if =>  Proc.new{|s| s.priority_changed? }
  named_scope :without_graded,:conditions => {:is_activity => false}
  before_create :set_priority
  
  def name_with_code
    "#{name}&#x200E;(#{code})&#x200E;"
  end
  
  def set_priority
    last_priority = if self.parent_type == 'Course'
        course.subject_components_for_priority.last.try(:priority)
      elsif self.parent_type == 'SubjectGroup'
        last_element = self.parent.sorted_components.select{|c| !c.new_record? }.last
        priority = last_element.present? ? last_element.priority : self.parent.priority
#      unless last_element.present?
        other_higer_components = course.subject_components_for_priority.select{|c| c.priority > priority}
        other_higer_components.each do |c| 
          c.priority = c.priority + 1
          c.save
        end
#      end
      
      priority
    else
      last_element = self.parent.course_subjects.select{|c| !c.new_record? }.last
      priority = last_element.present? ? last_element.priority : self.parent.priority
#      unless last_element.present?
        other_higer_components = course.subject_components_for_priority.select{|c| c.priority > priority}
        other_higer_components.each do |c| 
          c.priority = c.priority + 1
          c.save
        end
#      end
      
      priority
    end
    
    self.priority = last_priority.present? ? (last_priority + 1) : 0
  end
  
  def check_and_destroy
    if dependency_present?
      return false
    else
      self.destroy
    end 
  end
  
  def is_primary?
    self.parent_type == 'Course'
  end
  
  def dependency_present?
    self.subjects.active.present?
  end
  
  def reset_skill_set
    self.subject_skill_set_id = nil if self.is_activity?
  end
  
  def sync_priority
    subjects.each{|s| s.update_attribute('priority',self.priority )}
  end
  
  def set_subject_attributes
    subjects.each do |subject|
      next unless subject.new_record?
      subject.attributes = self.attributes.except('parent_id','parent_type','created_at','updated_at', 'course_id', 'import_from', 'previous_id')
    end
  end
  
  def self.configure_priorities(subject_params)
    return unless subject_params.present?
    subjects = find_all_by_id(subject_params.keys).to_a
    subject_params.each_pair do |s_id, prio|
      subject = subjects.find{|s| s.id == s_id.to_i}
      subject.priority = prio
      subject.save
    end
  end
  
  def check_grade_type
    unless self.course.nil?
      course.gpa_enabled? or course.cwa_enabled?
    else
      return false
    end
  end
  
  
  
end
