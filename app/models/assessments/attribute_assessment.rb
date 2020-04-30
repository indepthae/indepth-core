class AttributeAssessment < ActiveRecord::Base
  belongs_to :assessment_group_batch #check and remove the association
  belongs_to :subject_attribute_assessment
  belongs_to :subject #check and remove the association
  belongs_to :assessment_attribute_profile #check and remove the association
  belongs_to :assessment_attribute
  has_many :assessment_marks, :as => :assessment,:dependent => :destroy
  before_save :check_marks
  before_save :check_status_change, :if=> Proc.new{|as| as.submission_status_changed? and as.submission_status.nil? }
  named_scope :marks_added_assessments, {:conditions => {:marks_added => true}}
  
  accepts_nested_attributes_for :assessment_marks, :reject_if => lambda{|a| ((a[:is_absent] == "false") and a[:id].blank? and a[:marks].blank?) },:allow_destroy => true
  
  SUBMISSION_STATUS = {1 => t('marks_submitting'), 2 => t('marks_submitted'), 3 => t('marks_submission_failed')}
  
  def validate
    all_marks = assessment_marks.group_by(&:student_id)
    all_marks.each do |student_id, marks|
      if marks.length > 1
        old_data = marks.detect{|m| !m.new_record?}
        new_data = marks.select{|m| m.new_record?}
        old_data.attributes = {:marks => new_data.first.marks, :grade => new_data.first.grade,
          :grade_id => new_data.first.grade_id, :is_absent => new_data.first.is_absent} if new_data.present?
        new_data.each{|m| m.mark_for_destruction}
      end
    end
  end
  
  def check_marks
    assessment_marks.each do |am|
      am.mark_for_destruction if !am.new_record? and !am.is_absent and am.marks.blank? and am.grade_id.blank? and am.grade.blank?
    end
  end
  
  def submission_status_text
    submission_status.present? ? SUBMISSION_STATUS[submission_status] : t('no_marks_entered')
  end
  
  def check_status_change
    subject_attribute_assessment.update_attributes(:submission_status => nil) if subject_attribute_assessment.submission_status == 2
  end
  
end
