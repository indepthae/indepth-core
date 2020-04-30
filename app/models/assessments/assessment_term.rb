class AssessmentTerm < ActiveRecord::Base
  belongs_to :assessment_plan
  has_many :assessment_groups, :as => :parent, :dependent => :destroy
  has_many :generated_reports, :as => :report
  has_many :individual_reports, :as => :reportable
  has_many :gradebook_records, :as => :linkable
  has_many :gradebook_remarks, :as => :reportable
  attr_accessor :academic_year_id
  validates_uniqueness_of :name, :case_sensitive => false, :scope => :assessment_plan_id
  validates_presence_of :start_date, :end_date, :unless => :importing
  validates_presence_of :name
  validate :check_date_range
  after_destroy :update_term_count
  
  attr_accessor :importing
  
  def update_term_count
    plan = assessment_plan
    plan.terms_count = plan.terms_count - 1
    plan.send(:update_without_callbacks)
  end
  
  def validate
    unless start_date.nil? or end_date.nil?
      errors.add(:end_date,:end_date_cant_before_start_date) if self.end_date < self.start_date
    end
  end
  
  def has_employee_privilege
    true #Todo: Change in phase 2
  end
  
  def has_dependencies?
    assessment_plan.terms_count == 1 or assessment_groups.present?
  end
  
  
  def check_date_range
    unless start_date.nil? or end_date.nil? or academic_year_id.nil?
      ay = AcademicYear.find academic_year_id
      error1 = self.start_date < ay.start_date
      error2 = self.end_date > ay.end_date
      errors.add(:start_date,"#{t('should_be_after_ay_start')}") if error1
      errors.add(:end_date,"#{t('should_be_before_ay_end')}") if error2
    end
  end
  
  def final_assessment_added?
    final_assessment.present?
  end
  
  def final_assessment
    return(self.assessment_groups.first(:conditions => ['assessment_groups.type = ? and assessment_groups.is_final_term = ?', 'DerivedAssessmentGroup', true]) || DerivedAssessmentGroup.new(
      :parent => self,
      :scoring_type => 1,
      :assessment_plan_id => self.assessment_plan.id,
      :academic_year_id => self.academic_year_id,
      :is_final_term => true
    ))
  end
  
  def academic_year
    self.assessment_plan.academic_year
  end
  
  def term_name_with_span
    "#{self.name} <span>&#x200E;(#{term_span})&#x200E;</span>"
  end
  
  def term_span
    "#{format_date(start_date,:format => :month_year)} - #{format_date(end_date,:format => :month_year)}"
  end
  
  def term_name_with_max_marks
    final_assessment_added? ? "#{self.name} &#x200E;(#{self.final_assessment.maximum_marks})&#x200E;" : self.name
  end
  
  def get_assessment_groups_for_term_report
    groups = self.assessment_groups.all(:conditions => ['assessment_groups.is_final_term = ? AND assessment_groups.type <> ?', false, 'ActivityAssessmentGroup'],
      :include => {:assessment_group_batches => {:subject_attribute_assessments => {:attribute_assessments => :assessment_attribute}}})
    DerivedAssessmentGroup.extract_displayable_assessment_groups(groups,'term')
  end
  
  def has_report?(course_id)
    report = course_report(course_id)
    report.present? and report.generated_report_batches.completed_batches.present?
  end
  
  def course_report(course_id)
    generated_reports.first(:conditions => {:course_id => course_id})
  end
  
  def fetch_record_data(s_id,grg,flag)
    record_data = []
    rows = []
    grg.gradebook_records.each{|gr| rows<< gr.record_group.records.to_a.select{|r| r.input_type != "attachment"}.count}
    gradebook_record = grg.gradebook_records.to_a.find{|gr| (gr.linkable_id==self.id and gr.linkable_type==self.class.to_s)}
    if gradebook_record.present?
      record_group = gradebook_record.record_group
      records = record_group.records.to_a.select{|r| r.input_type != "attachment"}
#      rows << records.count
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
    if self.inherit_from_exam_enabled?
        exam_remarks = get_inherited_remarks(s_id)
        remarks_data << exam_remarks if exam_remarks.flatten.present?
    end
    gradebook_remarks = self.gradebook_remarks.select{|gr| gr.remarkable_type == "RemarkSet" and gr.student_id == s_id}
    gradebook_remarks.each do |remark|
      remark_set_name = remark.remarkable.name
      remarks_data << [remark_set_name, self.name, remark.remark_body] if remark.remark_body.present?
    end
    remarks_data
  end
  
  def subject_and_derived_assessments
    assessment_groups.all(:conditions => ["type <> ?", 'ActivityAssessmentGroup'])
  end
  
  def inherit_from_exam_enabled?
    ars = AssessmentReportSetting.find_by_assessment_plan_id_and_setting_key(self.assessment_plan_id,"InheritRemarkFromExam")
    ars.setting_value == "1"
  end
  
  def get_inherited_remarks(s_id)
    assessment_group_ids = self.assessment_groups.collect(&:id)
    grs = GradebookRemark.find_all_by_student_id_and_reportable_type_and_remarkable_type(s_id,"AssessmentGroup","RemarkSet", 
      :conditions => ["reportable_id in (?)",assessment_group_ids] ,:include => :reportable)
    gradebook_remarks_hash = grs.group_by(&:remarkable_id)
    remarks_data = []
    gradebook_remarks_hash.each do |k,gradebook_remarks|
      each_remark_sets = []
      gradebook_remarks.each do |remark|
        remark_set_name = remark.remarkable.name
        each_remark_sets << [remark_set_name, remark.reportable.display_name, remark.remark_body] if remark.remark_body.present?
      end
      remarks_data << each_remark_sets
    end
    remarks_data
  end

  def report_groups
    final_ass = final_assessment
    if final_ass.present?
      final_ass.all_assessment_groups_for_report('term') << final_ass
    else
      get_assessment_groups_for_term_report
    end
  end
  
  def activity_groups
    self.assessment_groups.all(:conditions => {:type => 'ActivityAssessmentGroup'}, 
                  :include => {:assessment_group_batches => {:activity_assessments => :assessment_activity}})
  end
  
    
  def build_manual_attendance(s_id,attendance_entries)
    attendance_entries.to_a.find{|obj| obj.linkable_id == self.id and obj.linkable_type  == "term" and obj.student_id == s_id}
  end
  
  def build_automatic_attendance(attendances,student,assessment_dates,batch,holidays)
    Attendance.student_leaves_total(attendances,student,batch,self.start_date,self.end_date,holidays)
  end
  
  def subjectwise_attendance(student,batch,subjects,assessment_date,holiday_event_dates)
    subject_wise_leave = {}
    subject_wise_leave = Attendance.calculate_subjectwise_attendance(student,batch,subjects,self.start_date,self.end_date,holiday_event_dates)
    return subject_wise_leave
  end
  #cumulative is the attendance between academic year starting date and end of assessment term end date
  def cumulative_subjectwise_attendance(student,batch,subjects,assessment_date,holiday_event_dates)
    cumulative_subject_wise_leave = {}
    start_date = assessment_plan.try(:academic_year).try(:start_date)
    cumulative_subject_wise_leave = Attendance.calculate_subjectwise_attendance(student,batch,subjects,start_date,self.end_date,holiday_event_dates)
    return cumulative_subject_wise_leave
  end
  
  def reportable_type_for_attendance
    "term"
  end
   
  def assessment_term_of_reportable
    [self]
  end
  
  def get_assessment_groups
    self.assessment_groups
  end
  
  def display_name
    self.name
  end
  
end
