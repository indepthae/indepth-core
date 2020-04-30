class AssessmentAttribute < ActiveRecord::Base
  
  belongs_to :assessment_attribute_profile
  
  validates_presence_of :maximum_marks, :if => Proc.new {|aa| aa.name.present?}
  validates_presence_of :name, :if => Proc.new {|aa| aa.maximum_marks.present?}
  validates_numericality_of :maximum_marks, :greater_than => 0, :if => Proc.new {|aa| aa.maximum_marks.present?}
  
  def name_with_max_mark
    "#{name}#{maximum_marks.present? ? " &#x200E;(#{maximum_marks})&#x200E;" : ""}"
  end
  
  def parent_name_and_type(subject)
    [subject.name, 'Subject', subject.id]
  end
  
  def is_activity?
    false #Fallback method for using report generation methods
  end
  
  def minimum_marks
    nil
  end
  
end
