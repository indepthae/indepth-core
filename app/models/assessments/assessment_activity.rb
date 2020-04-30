class AssessmentActivity < ActiveRecord::Base
  
  belongs_to :assessment_activity_profile
  has_many :converted_assessment_marks, :as => :markable
  
  validates_presence_of :name, :if => Proc.new {|aa| aa.description.present?}
#  validates_presence_of :description, :if => Proc.new {|aa| aa.name.present?}
  validates_length_of :description, :maximum => 250

  
end
