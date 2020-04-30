# To change this license header, choose License Headers in Project Properties.
# To change this template file, choose Tools | Templates
# and open the template in the editor.

class SubjectAttributeAssessment < ActiveRecord::Base
  belongs_to :assessment_group_batch
  belongs_to :batch
  belongs_to :subject
  belongs_to :assessment_attribute_profile
  before_save :check_status_change, :if=> Proc.new{|as| as.submission_status_changed? and as.submission_status.nil? }
  after_destroy :change_agb_status, :destroy_marks
  after_create :change_agb_status
  
  has_many :attribute_assessments,:dependent => :destroy
#  accepts_nested_attributes_for :attribute_assessments, :allow_destroy => true
  attr_accessor :attribute_assessments_attributes
  
  after_create :insert_assessments
  
  def insert_assessments
    self.assessment_attribute_profile.assessment_attributes.each do |attr|
      self.attribute_assessments.create(:assessment_attribute_id=>attr.id)
    end
  end
  
  def save_nested
    attribute_assessments_attributes.each_pair do |_,aaa|
      assessment = attribute_assessments.to_a.find{|a| a.id.to_s == aaa[:id] } if aaa[:id].present?
      next unless assessment.present?
      assessment.update_attributes(aaa)
    end
  end
  
  def fetch_attribute_scores
    scores = Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
    self.attribute_assessments.all(:include=>:assessment_marks).each do |assess|
      assess.assessment_marks.each do |mark|
        scores['marks'][assess.id][mark.student_id] = mark
        scores['presence'][mark.student_id] = false if mark.is_absent
      end
    end
    return scores
  end
  
  def destroy_marks
    ConvertedAssessmentMark.delete_all(["assessment_group_batch_id = ? AND markable_id = ? AND markable_type = ?", assessment_group_batch_id, subject_id, 'Subject'])
  end
  
  def submit_marks(students)
    valid = true
    self.reload
    assessments = self.attribute_assessments
    
    assessments.each do |assessment|
      student_ids = assessment.assessment_marks.collect(&:student_id)
      students.each{ |st| valid = false unless student_ids.include? st.s_id}
    end
    
    if valid
      assessments.each do |assessment|
        valid = false unless assessment.update_attributes(:submission_status => 1)
      end
      if valid
        valid = self.update_attributes(:submission_status => 1)
        Delayed::Job.enqueue(DelayedAssessmentMarksSubmission.new(id, self.class.to_s),{:queue => "gradebook_marks_submission"}) if valid
      end
    end
    return valid
  end
  
  def submission_status_text
    submission_status.present? ? AttributeAssessment::SUBMISSION_STATUS[submission_status] : t('no_marks_entered')
  end
  
  def check_status_change
    agb = self.assessment_group_batch
    if agb.submission_status == 2 or agb.marks_added == true
      agb.submission_status = nil
      agb.marks_added = false
    end
    agb.send(:update_without_callbacks)
  end
  
  def change_agb_status
    agb = self.assessment_group_batch
    status = agb.subject_attribute_assessments.all(:conditions => {:marks_added => false}).blank?
    change_marks_added_status(agb, status)
  end
  
  def change_marks_added_status(group_batch, status)
    if group_batch
      group_batch.reload
      group_batch.marks_added = status
      group_batch.send(:update_without_callbacks) if group_batch.marks_added_changed?
    end
  end
end
