class SubjectAssessment < ActiveRecord::Base
  belongs_to :assessment_group_batch
  belongs_to :subject
  belongs_to :batch
  has_many :assessment_marks, :as => :assessment, :dependent => :destroy
  has_one :event, :as => :origin, :dependent => :destroy
  attr_accessor :assessment_form_field_id, :batch_id, :course_id, :subject_list
  before_save :check_marks
  before_create :add_missing_skill_set_id
  after_create :create_assessment_event, :change_agb_status
  after_create :insert_assessments, :if => :has_skill_assessments
  after_save :lock_or_unlock_mark_entry_based_on_mark_entry_last_date
  after_update :update_assessment_event
  after_update :check_submitted_marks
  after_destroy :destroy_marks, :change_agb_status
  has_many :skill_assessments, :dependent => :destroy
  accepts_nested_attributes_for :skill_assessments, :allow_destroy => true
  belongs_to :subject_skill_set
  named_scope :marks_added_assessments, {:conditions => {:marks_added => true}}
  named_scope :without_skill_exams, {:conditions => {:has_skill_assessments => false}}
  named_scope :assessments_with_skills, {:include => [:subject, :assessment_marks, {:skill_assessments => [:assessment_marks,:subject_skill, {:sub_skill_assessments => [:assessment_marks, :subject_skill]}]}]} 
  named_scope :order_by_exam_date_and_start_time, {:order => "CONCAT(subject_assessments.exam_date, ' ', subject_assessments.start_time)"}
  
  accepts_nested_attributes_for :assessment_marks, :allow_destroy => true, :reject_if => lambda{|a| ((a[:is_absent] == "false") and a[:id].blank? and a[:grade_id].blank? and a[:marks].blank?) }
  before_save :check_status_change, :if=> Proc.new{|as| as.submission_status_changed? and as.submission_status.nil? }
  
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
  
  def add_missing_skill_set_id
    if subject.subject_skill_set_id.present? and !self.has_skill_assessments and self.assessment_group_batch.assessment_group.consider_skills
      self.has_skill_assessments = true
      self.subject_skill_set_id = subject.subject_skill_set_id
    end
  end
  
  def has_marks?
    if has_skill_assessments and subject_skill_set_id.present?
      skill_assess = self.skill_assessments.all(:include => [:assessment_marks, {:sub_skill_assessments => :assessment_marks}])
      truth_array = []
      skill_assess.each do |skill_ass|
        truth_array << skill_ass.assessment_marks.present?
        skill_ass.sub_skill_assessments.each do |sub_skill_ass|
          truth_array << sub_skill_ass.assessment_marks.present?
        end
      end
      truth_array.include?(true)
    else
      self.assessment_marks.present?
    end
  end
  
  def destroy_marks
    ConvertedAssessmentMark.delete_all(["assessment_group_batch_id = ? AND markable_id = ? AND markable_type = ?", assessment_group_batch_id, subject_id, 'Subject'])
  end
  
  def change_agb_status
    agb = self.assessment_group_batch
    if agb.subject_assessments.all(:conditions => {:marks_added => false}).blank?
      change_marks_added_status(agb, true)
    end
  end
  
  def insert_assessments
    self.subject_skill_set.subject_skills.each do |skill|
      skill_assessment = self.skill_assessments.create(:subject_skill_id => skill.id, :subject_id => self.subject_id, :assessment_group_batch_id => self.assessment_group_batch_id)
      skill.sub_skills.each do |sub_skill|
        skill_assessment.sub_skill_assessments.create(:subject_skill_id => sub_skill.id, :subject_id => self.id, :assessment_group_batch_id => self.assessment_group_batch_id)
      end
    end
  end
  
  def lock_or_unlock_mark_entry_based_on_mark_entry_last_date
    if self.assessment_group_batch.present? and self.assessment_group_batch.mark_entry_last_date.present?
      if self.assessment_group_batch.mark_entry_last_date < Date.today
        self.mark_entry_locked = true
      else
        self.mark_entry_locked = false
      end    
      self.unlocked = false
      self.send(:update_without_callbacks)
    end  
  end  
  
  def change_marks_added_status(group_batch, status)
    if group_batch
      group_batch.reload
      group_batch.marks_added = status
      group_batch.send(:update_without_callbacks)
    end
  end
  
  def check_submitted_marks
    if self.changes.present? and self.changes.include? 'subject_id'
      ConvertedAssessmentMark.delete_all(["assessment_group_batch_id = ? AND markable_id = ? AND markable_type = ?", assessment_group_batch_id, self.subject_id_was, 'Subject'])
    end
  end
  
  def create_assessment_event
    if self.event.blank?
      batch = assessment_group_batch.batch
      group = assessment_group_batch.assessment_group
      params = {:event => {:title => "#{t('exam_text')}", :description => "#{group.name} #{t('for')} #{batch.full_name} - #{self.subject.name}",
          :is_common => false, :start_date => start_date_time, :end_date => end_date_time, :is_exam => true, 
          :origin => self, :batch_events_attributes =>{1=>{:batch_id => batch.id, :selected => "1"}}}}
      new_event = Event.new(params[:event])
      new_event.save
    end
  end
  
  def  update_assessment_event
    batch = assessment_group_batch.batch
    group = assessment_group_batch.assessment_group
    self.event.update_attributes(:start_date => start_date_time, :end_date => end_date_time, 
      :description => "#{group.name} for #{batch.full_name} - #{self.subject.name}") unless self.event.blank?
  end
  
  def start_date_time
    DateTime.new(exam_date.year, exam_date.month,
      exam_date.day, start_time.hour,
      start_time.min, start_time.sec)
  end
  
  def end_date_time
    DateTime.new(exam_date.year, exam_date.month,
      exam_date.day, end_time.hour,
      end_time.min, end_time.sec)
  end
  
  def submission_status_text
    submission_status.present? ? SUBMISSION_STATUS[submission_status] : t('no_marks_entered')
  end
  
  def build_student_marks(students,mark_entry_locked)
    marks = self.assessment_marks.all(:include => :grade_details)
    assessment_scores = []
    students.each_with_index do |student, idx|
      student_mark = marks.detect{|m| m.student_id == student.s_id}
      assessment_scores << if student_mark.present?
        student_mark.attributes = {:sl_no => (idx+1),
          :student_name => student.full_name, 
          :student_roll_no => student.roll_number,
          :student_admission_no => student.admission_no}
        student_mark
      else
        if mark_entry_locked
          self.assessment_marks.build(:student_id => student.s_id, 
            :sl_no => (idx+1),
            :student_name => student.full_name, 
            :student_roll_no => student.roll_number,
            :student_admission_no => student.admission_no,
            :is_absent => true)
        else
          self.assessment_marks.build(:student_id => student.s_id, 
            :sl_no => (idx+1),
            :student_name => student.full_name, 
            :student_roll_no => student.roll_number,
            :student_admission_no => student.admission_no)
        end
      end
    end
    assessment_scores
  end
  
  def check_marks
    assessment_marks.each do |am|
      am.mark_for_destruction if !am.new_record? and !am.is_absent and am.marks.blank? and am.grade_id.blank?
    end
  end
  
  def maximum_marks_text
    if maximum_marks.present? and minimum_marks.present?
      "#{maximum_marks} &#x200E;(#{t('pass_text')} - #{minimum_marks})&#x200E;"
    elsif maximum_marks.present?
      "#{maximum_marks}"
    else
      "-"
    end
  end
  
  def submit_marks(students)
    self.reload
    valid = true
    student_ids = assessment_marks.collect(&:student_id)
    students.each{ |st| valid = false unless student_ids.include? st.s_id }
    if valid
      valid = self.update_attributes(:submission_status => 1)
      Delayed::Job.enqueue(DelayedAssessmentMarksSubmission.new(id, self.class.to_s),{:queue => "gradebook_marks_submission"}) if valid
    end
    return valid
  end
  
  def submit_skill_marks(students)
    self.reload
    valid = true
    if self.has_skill_assessments?
      student_ids = []
      assessments = self.skill_assessments.all(:include => [:assessment_marks , {:sub_skill_assessments => :assessment_marks}])
      assessments.each do |as|
        if as.sub_skill_assessments.present?
          as.sub_skill_assessments.each do |s_as|
            student_ids = s_as.assessment_marks.collect(&:student_id)
            students.each{ |st| valid = false unless student_ids.include? st.s_id}
          end
        else
          student_ids = as.assessment_marks.collect(&:student_id)
          students.each{ |st| valid = false unless student_ids.include? st.s_id}
        end
      end
    end
    if valid
      assessments.each do |as|
        as.sub_skill_assessments.each do |s_as|
          valid = false unless s_as.update_attributes(:submission_status => 1)
        end
        valid = false unless as.update_attributes(:submission_status => 1)
      end
      if valid
        valid = self.update_attributes(:submission_status => 1)
        Delayed::Job.enqueue(DelayedAssessmentMarksSubmission.new(id, self.class.to_s),{:queue => "gradebook_marks_submission"}) if valid
      end
    end
    return valid
  end
  
  def check_status_change
    agb = self.assessment_group_batch
    if agb.submission_status == 2 or agb.marks_added == true
      agb.submission_status = nil
      agb.marks_added = false
    end
    agb.send(:update_without_callbacks)
  end
  
  def fetch_skill_scores
    scores = Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
    self.skill_assessments.all(:include=>[:assessment_marks, {:sub_skill_assessments => :assessment_marks}]).each do |assess|
      assess.assessment_marks.each do |mark|
        scores['marks'][assess.id][mark.student_id] = mark
        scores['presence'][mark.student_id] = false if mark.is_absent
      end
      assess.sub_skill_assessments.each do |s_assess|
        s_assess.assessment_marks.each do |s_mark|
          scores['marks'][s_assess.id][s_mark.student_id] = s_mark
          scores['presence'][s_mark.student_id] = false if s_mark.is_absent
        end
      end
    end
    return scores
  end
  
end
