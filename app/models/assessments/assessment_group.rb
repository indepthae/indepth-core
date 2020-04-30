class AssessmentGroup < ActiveRecord::Base
  attr_accessor :batches_id
  
  belongs_to :parent, :polymorphic => true
  belongs_to :assessment_plan
  belongs_to :assessment_activity_profile
  belongs_to :assessment_attribute_profile
  belongs_to :academic_year
  belongs_to :grade_set
  has_many :derived_assessment_groups_associations
  has_many :derived_assessment_groups, :through => :derived_assessment_groups_associations
  has_many :assessment_group_batches, :dependent => :destroy
  has_many :batches, :through => :assessment_group_batches
  has_many :assessment_schedules
  has_many :converted_assessment_marks
  has_many :gradebook_records, :as => :linkable
  has_many :generated_reports, :as => :report
  has_many :individual_reports, :as => :reportable
  has_many :override_assessment_marks, :dependent => :destroy
  has_many :assessment_dates
  has_many :gradebook_remarks, :as => :reportable
  accepts_nested_attributes_for :override_assessment_marks , :allow_destroy => true ,:reject_if =>
    lambda{|a| (a[:type] == "ActivityAssessmentGroup")}
  
  validates_presence_of :name, :code, :display_name, :if => :check_no_exam
  #  validates_presence_of :parent_id, :parent_type
  validates_uniqueness_of :code, :scope => :assessment_plan_id, :if => "assessment_plan_id.present?", :unless => :no_exam
  validates_length_of :code , :maximum => 6, :message => :code_max_6_characters, :unless => :no_exam
  validates_format_of :code, :with => /^[a-zA-Z\d]+$/, :message => :should_contain_only_capital_letters_and_digits, :if => "code.present? and code.length < 7", :unless => :no_exam
  validates_format_of :code, :with => /^[a-zA-Z]{1}/, :message => :code_should_begin_with_letters, :if => "code.present? and code.length < 7 and !code.match(/^[a-zA-Z0-9]+$/).nil?", :unless => :no_exam
  validates_numericality_of  :maximum_marks,:greater_than => 0, :if => Proc.new { |p| ([1, 3].include? p.scoring_type.to_i) }, :unless => :no_exam
  validates_numericality_of  :minimum_marks,:greater_than_or_equal_to => 0, :if => Proc.new { |p| (p.scoring_type.to_i == 1) }, :unless => :no_exam
  validate :check_min_and_max_marks, :if => Proc.new { |p| p.maximum_marks.present? and p.minimum_marks.present? }, :unless => :no_exam
  validate :check_dependencies_for_derived
  after_save :set_batches
  before_validation :update_code_case
  named_scope :without_derived , {:conditions=> ['type != ?', 'DerivedAssessmentGroup']}
  named_scope :derived_groups , {:conditions=> ['type = ?', 'DerivedAssessmentGroup']}
  named_scope :without_final , {:conditions=> {:is_final_term => false}}
  
  attr_accessor :old_type
  
  SCORE = {1 => "marks", 2 => "grades", 3 => "marks_and_grades"}
  AssessmentType = Struct.new(:subject, :activity, :subject_attribute, :subject_wise_attribute)
  
  def update_code_case
    self.code = code.upcase
    self.display_name = display_name.upcase
  end
  def check_dependencies_for_derived
    if self.type_changed? and self.old_type != self.type # and self.old_type == "DerivedAssessmentGroup"
      errors.add(:type, :cant_change_assessment_type) if self.assessment_group_batches.present?
    end
  end
  
  def check_no_exam
    if self.no_exam
      if self.parent_type == "AssessmentTerm"
         return true
      else
        return false
      end
    end
    true
  end
  
  def maximum_marks_for(subject, course)
    max_marks = if self.override_assessment_marks.present?
      self.override_assessment_marks.find_by_subject_code_and_course_id(subject.code, course.id).try(:maximum_marks) ||  self.maximum_marks
    else
      self.maximum_marks
    end
    return max_marks.to_f
  end
  
  def maximum_marks_with_code(code, course)
    max_marks = if self.override_assessment_marks.present?
      self.override_assessment_marks.find_by_subject_code_and_course_id(code, course.id).try(:maximum_marks) ||  self.maximum_marks
    else
      self.maximum_marks
    end
    return max_marks.to_f
  end
  
  def overrided_mark(subject,course_id)
    if self.override_assessment_marks.present?
      max_marks = self.override_assessment_marks.find_by_subject_code_and_course_id(subject.code, course_id).try(:maximum_marks)
      max_marks.present? ? "&#x200E;(#{max_marks.to_f})&#x200E;" : ""
    else
      ""
    end
  end
  
  def build_override_marks(params)
    if params.present?
      params.each_pair do |key, osm_param|
        self.override_assessment_marks.build(osm_param)
      end
    end
  end
  
  def check_min_and_max_marks
    if self.scoring_type.to_i == 1
      errors.add(:minimum_marks, :minmarks_cant_be_more_than_maxmarks) if minimum_marks > maximum_marks
    end
  end
  
  def has_employee_privilege
    true #Todo: Change in phase 2
  end
  
  def term_wise?
    parent_type == 'AssessmentTerm'
  end
  
  def plan_wise?
    parent_type == 'AssessmentPlan'
  end
  
  def grade_type?
    scoring_type == 2
  end
  
  def mark_and_grade_type?
    scoring_type == 3
  end
  
  def create_assessments(batch_ids,course,subject_wise_assessment = false)
    agbs = self.assessment_group_batches.all(:conditions=>['batch_id in (?) and course_id = ?',batch_ids,course.id])
    new_batch_ids = batch_ids.map(&:to_i) - agbs.collect(&:batch_id)
    hashes = new_batch_ids.map {|batch_id| {:batch_id=>batch_id,:course_id=>course.id, :subject_wise_assessment => subject_wise_assessment }}
    self.assessment_group_batches.create(hashes)
  end

  def validate
    plan_id = unless parent_type == "Course"
      assessment_plan_id
    else
      parent.assessment_plans.all(:joins => :academic_year, :conditions => "academic_years.is_active = 1").first.try(:id)
    end
    codes = if plan_id
      AssessmentPlan.all(:joins => {:courses => :assessment_groups}, :select => "assessment_groups.id, assessment_groups.code",
        :conditions => ["assessment_plans.id = ?", plan_id]).collect(&:code)
    else
      (parent_type == "Course" ? parent.assessment_groups.all(:conditions => [(new_record? ? "" : "id <> #{id}")]).collect(&:code) : [])
    end
    errors.add(:code, :taken) if codes.include? code
  end
    
  def set_batches
    self.batches = Batch.all(:conditions => {:id => batches_id.split(",")}) if batches_id.present?
  end
  
  def fetch_batch_assessments(batch_ids)
    batch_assessments = Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
    type = exam_type
    batch_ids.each do |batch_id|
      assessments = if type.subject
        AssessmentGroupBatch.batch_subject_assessments(batch_id,self)
      elsif type.activity
        AssessmentGroupBatch.batch_actvity_assessments(batch_id,self)
      elsif type.subject_attribute or type.subject_wise_attribute
        AssessmentGroupBatch.batch_attribute_assessments(batch_id,self)
      else
        AssessmentGroupBatch.batch_derived_assessments(batch_id,self)
      end
      batch_assessments[batch_id]['assessments'] = assessments if assessments.present?
    end
    return batch_assessments
  end
  
  def fetch_inactive_assessments(batch_ids)
    subjects = {}
    if exam_type.subject_attribute
      batches = Batch.find(batch_ids)
      batches.each do |batch|
        subjects[batch.id] = AssessmentGroupBatch.batch_inactive_subjects(batch,self)
      end
    end
    return subjects
  end
  
  def insert_subject_attribute_assessments(batch_id, subject, type)
    if type.subject_attribute
      group_batch = assessment_group_batches.first(:conditions => {:batch_id => batch_id})
      assessment = group_batch.subject_attribute_assessments.new(:subject => subject, :assessment_attribute_profile_id => assessment_attribute_profile_id )
      return assessment.save
    else
      return false
    end
  end
    
  def update_attributes_changing_type(attrs) 
    object = if attrs.keys.include?('type') || attrs.keys.include?(:type)
      self.becomes((attrs['type'] || attrs[:type]).constantize)
    else
      self
    end
    object.class.instance_variable_set('@finder_needs_type_condition', :false)
    object.old_type = object.type
    object.type = object.class.to_s
    object.update_attributes(attrs)
    object.class.instance_variable_set('@finder_needs_type_condition', :true)
    object
  end
  
  def score_type
    (scoring_type.present? ? t(SCORE[scoring_type]) : t('grades'))
  end
  
  def exam_mode
    if final_term?
      t('final_term')
    elsif derived_assessment?
      t('derived_exam')
    else      
      prefix = subject_assessment? ? t('subject') : 'Activity'
      prefix += (prefix == 'Activity' or is_single_mark_entry?) ? ( consider_skills ? ' Skill' : '' ) : ' Attributes'
      "#{prefix} Exams"
    end
  end
  
  def assessment_group_type
    if derived_assessment?
      'Derived'
    else
      prefix = subject_assessment? ? 'Subject' : 'Activity'
      prefix += (prefix == 'Activity' or is_single_mark_entry?) ? ( consider_skills ? ' Skill' : '' ) : ' Attributes'
      prefix
    end
  end
  
  def skill_assessment?
    subject_assessment? and is_single_mark_entry? and consider_skills
  end
  
  def derived_assessment?
    type == 'DerivedAssessmentGroup'
  end
  
  def final_term?
    derived_assessment? and is_final_term?
  end
  
  def subject_assessment?
    type == 'SubjectAssessmentGroup'
  end
  
  def exam_type
    e_type = if final_term?
      t('final_term')
    elsif derived_assessment?
      t('derived_exam')
    else      
      prefix = subject_assessment? ? 'Subject' : 'Activity'
      prefix += (prefix == 'Activity' or is_single_mark_entry?) ? '' : ' Attributes'
      "#{prefix} Exams"
    end
    type = e_type.gsub(/\ /, '').underscore
    AssessmentType.new((type == 'subject_exams'),(type == 'activity_exams'),((type == 'subject_attributes_exams') and is_attribute_same?),((type == 'subject_attributes_exams') and !is_attribute_same?))
  end
  
  def name_with_code
    "#{name} &#x200E;(#{code})&#x200E;"
  end
  
  def name_with_max_marks
    "#{name}#{maximum_marks.present? ? " &#x200E;(#{maximum_marks})&#x200E;" : ""}"
  end
  
  def display_name_with_max_marks
    if self.hide_marks
      display_name
    else  
      "#{display_name}#{maximum_marks.present? ? " &#x200E;(#{maximum_marks})&#x200E;" : ""}"
    end
  end
  
  def display_name_with_percentage
    "#{display_name} &#x200E;(%)&#x200E;"
  end
  
  def marks_text_with_max_marks
    "#{t('marks')}#{maximum_marks.present? ? " &#x200E;(#{maximum_marks})&#x200E;" : ""}"
  end
  
  def total_marks_with_max_marks
    "#{t('total_mark')}#{maximum_marks.present? ? " &#x200E;(#{maximum_marks})&#x200E;" : ""}"
  end
  
  def display_details
    type = exam_type
    details = if type.activity
      [['exam_type',exam_mode],['activity_profile',assessment_activity_profile.name],['grading_profile',grade_set.name]]
    elsif type.subject_attribute
      profile = assessment_attribute_profile
      formula = (profile.formula == 'bestof')? 'Best of' : profile.formula.capitalize
      [['exam_type',exam_mode],['scoring',score_type],['max_marks',maximum_marks],['attributes_profile',profile.name],['formula', formula]]
    elsif type.subject_wise_attribute
      [['exam_type',exam_mode],['scoring',score_type],['max_marks',maximum_marks]]
    elsif type.subject
      [['exam_type',exam_mode],['scoring',score_type],['max_marks',maximum_marks],['grading_profile',grade_set.present? ? grade_set.name : '']]
    else
      [['exam_type',exam_mode],['scoring',score_type],['max_marks',maximum_marks],['grading_profile',grade_set.present? ? grade_set.name : '']]
    end
    return details
  end
  
  def scoring_details
    case scoring_type
    when 1
      {"#{t(:max_mark)} &#x200E;(#{t(:exam_group)})&#x200E;" => "#{maximum_marks} &#x200E;(#{t('pass_text')} - #{minimum_marks})&#x200E;"}
    when 2
      {t(:grading_profile) => grade_set.name}
    when 3
      {t(:grading_profile) => grade_set.name, "#{t(:max_mark)} &#x200E;(#{t(:exam_group)})&#x200E;" => maximum_marks}
    end
  end
  
  def is_course_exam?
    (parent_type == "Course")
  end
  
  def active_for(course)
    fetch_batch_assessments(course).present?
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
  
  def assessments_present?
    has_associated_records  = assessment_group_batches.map {|agb| agb.children?}
    has_associated_records.include?(true)
  end
  
  def check_and_destroy
    if assessments_present? or present_in_derived_groups?
      return false
    else
      self.destroy
      return true
    end
  end
  
  def present_in_derived_groups?
    DerivedAssessmentGroupsAssociation.find_all_by_assessment_group_id(self.id, :joins => :derived_assessment_group).present?
  end
  
  def assessments_with_marks_present?
    type = exam_type
    if type.subject
      assessment_group_batches.all(:joins => {:subject_assessments => :assessment_marks}).present?
    elsif type.activity
      assessment_group_batches.all(:joins => {:activity_assessments => :assessment_marks}).present?
    else
      assessment_group_batches.all(:joins => {:attribute_assessments => :assessment_marks}).present?
    end
  end
  
  def course_report(course_id)
    generated_reports.first(:conditions => {:course_id => course_id})
  end
  
  def has_report?(course_id)
    report = course_report(course_id)
    report.present? and report.generated_report_batches.completed_batches.present?
  end
  
  def fetch_record_data(s_id,grg,flag)
    record_data = []
    rows = []
    grg.gradebook_records.each{|gr| rows<< gr.record_group.records.to_a.select{|r| r.input_type != "attachment"}.count}
    gradebook_record = grg.gradebook_records.to_a.find{|gr| (gr.linkable_id==self.id and gr.linkable_type==self.class.to_s)}
    if gradebook_record.present?
      record_group = gradebook_record.record_group
      records = record_group.records.to_a.select{|r| r.input_type != "attachment"}
      records.to_a.each do |record|
        student_record = record.student_records.to_a.find{|sa| sa.student_id==s_id}
        data = student_record.additional_info if student_record.present?
        data = format_date(data) if record.input_type == "date"
        data = data.present? ? data+' '+record.suffix : "-"
        record_data << [1,'<span class="record_name">'+record.name+':</span> '+data]
      end
      (0...(rows.max - records.length)).each{record_data<<[1,'']} if flag
    end
    record_data
  end
  
  def fetch_remark_data(s_id)
    remarks_data = []
    gradebook_remarks = self.gradebook_remarks.select{|gr| gr.remarkable_type == "RemarkSet" and gr.student_id == s_id}
    gradebook_remarks.each do |remark|
      remark_set_name = remark.remarkable.name
      remarks_data << [remark_set_name, remark.remark_body] if remark.remark_body.present?
    end
    remarks_data
  end
  
  def delete_schedules(course_id, batch_id)
    schedules = assessment_schedules.all(:conditions => {:course_id => course_id}, :include => :batches)
    schedules.each do |schedule|
      schedule.batch_ids = schedule.batch_ids - [batch_id]
      schedule.destroy if schedule.batch_ids.empty?
    end
  end
  
  def report_groups
    [self]
  end
  
  def activity_groups
    []
  end
  
  def build_manual_attendance(s_id,attendance_entries)
    attendance_entries.to_a.find{|obj| obj.linkable_id == self.id and obj.linkable_type  == "exam" and obj.student_id == s_id}
  end
  
  def build_automatic_attendance(attendances,student,assessment_dates,batch,holidays)
    assessment_date = assessment_dates.to_a.find{|obj| obj.assessment_group_id == self.id }
    if assessment_date.present?
      start_date = assessment_date.start_date
      end_date = assessment_date.end_date
      Attendance.student_leaves_total(attendances,student,batch,start_date,end_date,holidays)
    else
      return "-","-"
    end
  end
  
  def subjectwise_attendance(student,batch,subjects,assessment_dates,holiday_event_dates)
    assessment_date = assessment_dates.to_a.find{|obj| obj.assessment_group_id == self.id }
    subject_wise_leave = {}
    if assessment_date.present?
      start_date = assessment_date.start_date
      end_date = assessment_date.end_date
      subject_wise_leave = Attendance.calculate_subjectwise_attendance(student,batch,subjects,start_date,end_date,holiday_event_dates)
    end
    return subject_wise_leave
  end
  
  #cumulative is the attendance between academic year starting date and end of assessment_date 
  def cumulative_subjectwise_attendance(student,batch,subjects,assessment_dates,holiday_event_dates)
    assessment_date = assessment_dates.to_a.find{|obj| obj.assessment_group_id == self.id }
    cumulative_subject_wise_leave = {}
    if assessment_date.present?
      start_date = academic_year.try(:start_date)
      end_date = assessment_date.end_date
      cumulative_subject_wise_leave = Attendance.calculate_subjectwise_attendance(student,batch,subjects,start_date,end_date,holiday_event_dates)
    end
    return cumulative_subject_wise_leave  
  end
  
  def reportable_type_for_attendance
    "exam"
  end
  
  def assessment_term_of_reportable
    []
  end
  
  def get_assessment_groups
    [self]
  end
  
  def final_assessment
    self
  end
  
end
