class ActivityAssessment < ActiveRecord::Base
  
  belongs_to :assessment_group_batch
  belongs_to :assessment_activity_profile
  belongs_to :assessment_activity
  has_many :assessment_marks, :as => :assessment, :dependent => :destroy
  before_save :check_marks
  before_save :check_status_change, :if=> Proc.new{|as| as.submission_status_changed? and as.submission_status.nil? }
  delegate :name, :to => :assessment_activity_profile,:prefix => true, :allow_nil => true
  delegate :name, :to => :assessment_activity,:prefix => true, :allow_nil => true
  after_destroy :change_agb_status
  after_create :change_agb_status#, :if => Proc.new{|as| as.assessment_group_batch.activity_assessments.count > 1 }
  
  accepts_nested_attributes_for :assessment_marks,:reject_if => lambda{|a| ((a[:is_absent] == "0") and a[:id].blank? and a[:grade_id].blank?) },  :allow_destroy => true
  
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
  
  def activity
    AssessmentActivity.find assessment_activity_id
  end
  
  def build_student_marks(students)
    marks = self.assessment_marks
    assessment_scores = []
    students.each_with_index do |student, idx|
      student_mark = marks.detect{|m| m.student_id == student.s_id}
      assessment_scores << if student_mark.present?
        student_mark.attributes = {:sl_no => (idx+1),:student_name => student.full_name, :student_roll_no => student.roll_number,:student_admission_no => student.admission_no}
        student_mark
      else
        self.assessment_marks.build(:student_id => student.id, :sl_no => (idx+1), :student_name => student.full_name, :student_roll_no => student.roll_number,:student_admission_no => student.admission_no)
      end
    end
    assessment_scores
  end
  
  def check_marks
    assessment_marks.each do |am|
      am.mark_for_destruction if !am.new_record? and !am.is_absent and am.grade_id.blank?
    end
  end
  
  def submit_marks(students)
    self.reload
    valid = true
    student_ids = assessment_marks.collect(&:student_id)
    students.each{ |st| valid = false unless student_ids.include? st.id }
    if valid
      valid = self.update_attributes(:submission_status => 1)
      Delayed::Job.enqueue(DelayedAssessmentMarksSubmission.new(id, self.class.to_s),{:queue => "gradebook_marks_submission"}) if valid
    end
    return valid
  end
  
  def submission_status_text
    submission_status.present? ? SUBMISSION_STATUS[submission_status] : t('no_marks_entered')
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
    status = agb.activity_assessments.all(:conditions => {:marks_added => false}).blank?
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
