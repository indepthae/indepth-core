class AssessmentGroupBatch < ActiveRecord::Base
  
  attr_accessor :subject_list
  
  belongs_to :assessment_group
  belongs_to :batch
  belongs_to :course
  has_many :subject_assessments, :dependent => :destroy
  has_many :subject_attribute_assessments, :dependent => :destroy
  accepts_nested_attributes_for :subject_attribute_assessments, :allow_destroy => true, :reject_if => lambda { |l| l[:assessment_attribute_profile_id].blank? }
  has_many :attribute_assessments,:dependent => :destroy #Check and remove the association
  has_many :activity_assessments,:dependent => :destroy
  has_many :converted_assessment_marks, :dependent => :destroy
  
  attr_accessor_with_default :subject_wise_assessment,false
  
  accepts_nested_attributes_for :subject_assessments, :allow_destroy => true
  
  after_create :insert_assessments, :if=>Proc.new{|agb| !agb.subject_wise_assessment}
  before_save :check_assessments,  :if=> Proc.new{|agb| agb.assessment_group.exam_type.subject}
  before_save :check_dependents
  after_save :check_marks_added,  :if=> Proc.new{|agb| agb.assessment_group.exam_type.subject}
  validate :check_modification,  :if=> Proc.new{|agb| agb.assessment_group.exam_type.subject}
  
  before_save :set_course_id
  
  after_destroy :destroy_assessment_dates
  
  named_scope :course_assessment_groups, lambda{|course_id| {:select => "assessment_groups.*",
      :joins => [:assessment_group, :subject_assessments], :conditions => {:course_id => course_id}, :group => "assessment_groups.id"}}
  named_scope :assessment_group_batches, lambda{|group_id, course_id| {:select => "batches.*", :conditions => {:course_id => course_id, 
        :assessment_group_id => group_id}, :joins => [:subject_assessments, :batch], :group => "batches.id"}}
  named_scope :course_assessments, lambda{|group_id, course_id| {:select => "subject_assessments.*, 
        assessment_group_batches.batch_id, subjects.name AS subject_name, subjects.elective_group_id", 
      :conditions => {:course_id => course_id, :assessment_group_id => group_id}, :joins => {:subject_assessments => :subject}, 
      :include => [:batch], :order => "CONCAT(subject_assessments.exam_date, ' ', subject_assessments.start_time)"}}
  named_scope :batch_equals, lambda{|batch_id| {:conditions => {:batch_id => batch_id}}}
  
  include CsvExportMod
  
  SUBMISSION_STATUS = {1 => t('calculating_marks'), 2 => t('marks_calculated'), 3 => t('calculation_failed')}
   
  def children?
    subject_assessments.exists? || subject_attribute_assessments.all(:joins=>:attribute_assessments).present? || activity_assessments.exists?
  end
  
  def destroy_assessment_dates
    date = AssessmentDate.first(:conditions=>['batch_id = ? and assessment_group_id = ?',self.batch_id,self.assessment_group_id])
    date.destroy if date.present?
  end
  
  def childrens_present?
    subject_assessments.present? || subject_attribute_assessments.all(:joins=>:attribute_assessments).present? || activity_assessments.present?
  end
  
  def check_modification
    subject_assessments.each do |sub|
      sub_id = sub.subject_list.split('-').first.to_i if sub.subject_list.present?
      if !sub.new_record? and sub.assessment_marks.present? and (sub.exam_date_changed? or 
            sub.start_time_changed? or
            sub.end_time_changed? or 
            sub.maximum_marks_changed? or 
            sub.minimum_marks_changed? or
            (sub.subject_id_was != sub_id) )
        self.errors.add(:base, :changes_are_not_permitted)
      end
    end
  end
  
  def subject_ids
    (self.subject_attribute_assessments.collect(&:subject_id) + self.subject_assessments.collect(&:subject_id)).uniq
  end
  
  def build_attribute_assessments(subjects)
    subjects.each do |subject|
      saa = self.subject_attribute_assessments.find_by_subject_id(subject)
      self.subject_attribute_assessments.build(:subject => subject) unless saa
    end
  end
  
  def insert_assessments
    ag = assessment_group
    type = ag.exam_type
    if type.activity
      ag.assessment_activity_profile.assessment_activities.each do |act|
        self.activity_assessments.create(:assessment_activity_profile_id=>ag.assessment_activity_profile.try(:id),:assessment_activity_id=>act.id)
      end
    elsif type.subject_attribute
      batch.all_normal_subjects.each do |subject|
        self.subject_attribute_assessments.create(:subject => subject, :assessment_attribute_profile_id => ag.assessment_attribute_profile_id )
      end
    end
  end
  
  def subjects_with_marks
    unless self.new_record?
      self.subject_attribute_assessments.all(:joins => {:attribute_assessments =>:assessment_marks}).collect(&:subject_id).uniq.compact
    else
      []
    end
  end
  
  def check_dependents
    ag = assessment_group
    type = ag.exam_type
    if type.subject_attribute or type.subject_wise_attribute
      self.subject_attribute_assessments.each do |saa|
        saa.mark_for_destruction if saa.assessment_attribute_profile_id.blank?
      end
    end
  end
  
  def check_marks_added
    assessments = self.subject_assessments.all(:conditions => {:marks_added => false})
    if assessments.present?
      self.marks_added = false
      self.send(:update_without_callbacks)
    end
  end
  
  def set_course_id
    self.course_id = self.batch.course_id
  end
  
  def save_marks(marks_hash)
    marks_hash.each_pair do |ass_id,assessments|
      assess = AttributeAssessment.find(ass_id)
      assess.update_attributes(assessments)
    end
  end
  
  def submit_marks(students, marks_hash)
    valid = true
    all_assessments = []
    marks_hash.each_pair do |ass_id,assessments|
      assessment = AttributeAssessment.find(ass_id)
      all_assessments << assessment
      valid = true
      student_ids = assessment.assessment_marks.collect(&:student_id)
      students.each{ |st| valid = false unless student_ids.include? st.id }
    end
    if valid
      all_assessments.each do |assessment|
        valid = false unless assessment.update_attributes(:submission_status => 1)
      end
      Delayed::Job.enqueue(DelayedAssessmentMarksSubmission.new(marks_hash.keys, "AttributeAssessment"),{:queue => "gradebook_marks_submission"}) if valid
    end
    return valid
  end
  
  def submit_derived_marks
    valid =  self.update_attributes(:submission_status => 1)
    Delayed::Job.enqueue(DelayedAssessmentMarksSubmission.new(self.id, "AssessmentGroupBatch"),{:queue => "gradebook_marks_submission"}) if valid
    return valid
  end
  
  def fetch_attribute_scores(subject)
    scores = Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
    self.attribute_assessments.all(:include=>:assessment_marks,:conditions => {:subject_id => subject.id}).each do |assess|
      assess.assessment_marks.each do |mark|
        scores['marks'][assess.id][mark.student_id] = mark
        scores['presence'][mark.student_id] = false if mark.is_absent
      end
    end
    return scores
  end
  
  def create_attribute_wise_assessments(assessments)
    new_rec = self.new_record?
    save if new_rec
    ActiveRecord::Base.transaction do
      assessments.each_pair do |s_id,profile|
        next if profile["assessment_attribute_profile_id"].blank?
        attr_profile = AssessmentAttributeProfile.find profile["assessment_attribute_profile_id"]
        if new_rec
          insert_attribute_assessments(attr_profile, s_id)
        else
          asses = self.attribute_assessments.all.group_by(&:subject_id)
          if asses[s_id.to_i].present?
            unless asses[s_id.to_i].collect(&:assessment_attribute_profile_id).include? profile["assessment_attribute_profile_id"].to_i
              asses[s_id.to_i].each {|as| as.destroy}
              insert_attribute_assessments(attr_profile, s_id.to_i)
            end
          else
            insert_attribute_assessments(attr_profile, s_id.to_i)
          end
        end
      end
      assessments = self.attribute_assessments.all(:conditions => {:marks_added => false})
      self.update_attributes(:marks_added => false) if assessments.present?
    end
  end
  
  def insert_attribute_assessments(attr_profile, s_id)
    attr_profile.assessment_attribute_ids.each do |attr_id|
      ass = self.attribute_assessments.find_or_initialize_by_subject_id_and_assessment_attribute_profile_id_and_assessment_attribute_id(:subject_id => s_id,
        :assessment_attribute_profile_id => attr_profile.id,:assessment_attribute_id=>attr_id)
      if ass.new_record?
        ass.save
      end
    end
  end
  
  def check_assessments
    subject_assessments.each do |sub|
      unless sub.subject_list.present? and sub.exam_date.present? and sub.start_time.present? and sub.end_time.present?
        sub.mark_for_destruction 
      else
        subjects = sub.subject_list.split("-")
        sub.subject_id = subjects.first
        sub.elective_group_id = subjects.last if subjects.length > 1
      end
    end
  end
  
  def subjects_list
    (subject_assessments.marks_added_assessments.collect(&:subject_id) + subjects_in_attribute_assessments).uniq.sort
  end
  
  def subjects_in_attribute_assessments
    self.subject_attribute_assessments.all(:joins => :attribute_assessments, :conditions => {:attribute_assessments => {:marks_added => true}}).collect(&:subject_id).uniq.sort
  end
  
  def submission_status_text
    submission_status.present? ? SUBMISSION_STATUS[submission_status] : t('marks_not_calculated')
  end
  
  class << self
    def batch_attribute_assessments(batch,ag)
      agb_ids = all(:conditions=>{:batch_id=>batch,:assessment_group_id=>ag.id})
      SubjectAttributeAssessment.all(:conditions=>['assessment_group_batch_id in (?)',agb_ids], :include => :subject)
    end
    
    def batch_actvity_assessments(batch,ag)
      agb_ids = all(:conditions=>{:batch_id=>batch,:assessment_group_id=>ag.id})
      ActivityAssessment.all(:conditions=>['assessment_group_batch_id in (?)',agb_ids])
    end
    
    def batch_subject_assessments(batch,ag)
      agb_ids = all(:conditions=>{:batch_id=>batch,:assessment_group_id=>ag.id})
      SubjectAssessment.all(:conditions=>['assessment_group_batch_id in (?)',agb_ids], :order => "CONCAT(subject_assessments.exam_date, ' ', subject_assessments.start_time)", :include => :subject) 
    end
    
    def batch_derived_assessments(batch,ag)
      all(:conditions=>{:batch_id=>batch,:assessment_group_id=>ag.id})
    end
    
    def batch_attribute_assessments_with_marks(batch,ag)
      agb_ids = all(:conditions=>{:batch_id=>batch.id,:assessment_group_id=>ag.id})
      if batch.is_active?
        SubjectAttributeAssessment.all(:joins => {:attribute_assessments => {:assessment_marks => :student}},
          :conditions => ['subject_attribute_assessments.assessment_group_batch_id in (?) and students.batch_id = ?',agb_ids, batch.id])
      else
        SubjectAttributeAssessment.all(:joins => {:attribute_assessments => {:assessment_marks => {:student => :batch_students}}},
          :conditions => ['subject_attribute_assessments.assessment_group_batch_id in (?) and batch_students.batch_id = ?',agb_ids, batch.id])
      end
    end
    
    def batch_actvity_assessments_with_marks(batch,ag)
      agb_ids = all(:conditions=>{:batch_id=>batch.id,:assessment_group_id=>ag.id})
      if batch.is_active?
        ActivityAssessment.all(:conditions=>['assessment_group_batch_id in (?) and students.batch_id = ?',agb_ids, batch.id],
          :joins=> {:assessment_marks => :student})
      else
        ActivityAssessment.all(:conditions=>['assessment_group_batch_id in (?) and batch_students.batch_id = ?',agb_ids, batch.id],
          :joins=> {:assessment_marks => {:student => :batch_students}})
      end
    end
    
    def batch_subject_assessments_with_marks(batch,ag)
      agb_ids = all(:conditions=>{:batch_id=>batch.id,:assessment_group_id=>ag.id})
      s_ass = if batch.is_active?
        SubjectAssessment.all(:conditions=>['assessment_group_batch_id in (?) and students.batch_id = ? and has_skill_assessments = ?',agb_ids, batch.id, false],
          :include => :subject, :joins=>{:assessment_marks => :student}) + 
          SubjectAssessment.all(:conditions=>['subject_assessments.assessment_group_batch_id in (?) and students.batch_id = ? and has_skill_assessments = ?',agb_ids, batch.id, true],
          :include => :subject, :joins=>{:skill_assessments => {:assessment_marks => :student}}) + 
          SubjectAssessment.all(:conditions=>['subject_assessments.assessment_group_batch_id in (?) and students.batch_id = ? and has_skill_assessments = ?',agb_ids, batch.id, true],
          :include => :subject, :joins=>{:skill_assessments => {:sub_skill_assessments => {:assessment_marks => :student}}})
      else
        SubjectAssessment.all(:conditions=>['assessment_group_batch_id in (?) and batch_students.batch_id = ? and has_skill_assessments = ?',agb_ids, batch.id, false],
          :include => :subject, :joins=>{:assessment_marks => {:student => :batch_students}}) + 
          SubjectAssessment.all(:conditions=>['subject_assessments.assessment_group_batch_id in (?) and batch_students.batch_id = ? and has_skill_assessments = ?',agb_ids, batch.id, true],
          :include => :subject, :joins=>{:skill_assessments => {:assessment_marks => {:student => :batch_students}}}) + 
          SubjectAssessment.all(:conditions=>['subject_assessments.assessment_group_batch_id in (?) and batch_students.batch_id = ? and has_skill_assessments = ?',agb_ids, batch.id, true],
          :include => :subject, :joins=>{:skill_assessments => {:sub_skill_assessments => {:assessment_marks => {:student => :batch_students}}}})
      end
      s_ass.uniq
    end
    
    def batch_subject_assessments_for_sms(batch,ag)
      agb_ids = all(:conditions=>{:batch_id=>batch.id,:assessment_group_id=>ag.id})
      s_ass = if batch.is_active?
        SubjectAssessment.all(:conditions=>['assessment_group_batch_id in (?) ',agb_ids], :include => :subject)
      else
        []
      end
      s_ass.uniq
    end
    
    def build_sms_details(batch,ag)
      subject_assessments = batch_subject_assessments_for_sms(batch,ag)
      sms_details = {}
      sms_details[:exam_name] =  ag.name
      sms_details[:exam_schedule] = subject_assessments.collect{|se| "#{format_date(se.exam_date)} #{se.subject.name} (#{se.start_time.strftime("%I:%M %p")} - #{se.end_time.strftime("%I:%M %p")})"}.join(", ")
      sms_details[:recipients] =  batch.students.collect(&:id)
      return sms_details
    end
    
    def batch_inactive_subjects(batch,ag)
      assessments = batch_attribute_assessments(batch.id,ag)
      (batch.all_normal_subjects - assessments.collect(&:subject))
    end
    
    def fetch_exam_timings_data(params)
      exam_timings_data(params)
    end
   
  end
  
end
