class AssessmentPlan < ActiveRecord::Base
  
  belongs_to :academic_year
  has_many :assessment_terms, :dependent => :destroy
  accepts_nested_attributes_for :assessment_terms
  has_many :assessment_plans_courses
  has_many :courses, :through => :assessment_plans_courses
  has_many :assessment_groups, :as => :parent
  has_many :generated_reports, :as => :report
  has_many :individual_reports, :as => :reportable
  has_many :assessment_report_settings#,  :dependent => :destroy
  has_many :gradebook_record_groups
  has_many :gradebook_remarks, :as => :reportable
  has_many :remark_sets
  accepts_nested_attributes_for :gradebook_record_groups
  accepts_nested_attributes_for :remark_sets, :allow_destroy=>true
  accepts_nested_attributes_for :assessment_plans_courses, :allow_destroy => true, :reject_if => lambda { |l| l[:selected] == "0" }
  
  validates_presence_of :name
  validates_uniqueness_of :name, :case_sensitive => false, :scope => :academic_year_id
  
  validate :check_term_date_ranges
  before_save :check_courses
  
  MaxTermCount = 6.freeze
  
  def build_terms(count = nil)
    ac_year = academic_year
    if count
      count.times do |i|
        self.assessment_terms.build(:start_date => (i==0 ? ac_year.try(:start_date) : nil), :end_date => (i==(count-1) ? ac_year.try(:end_date) : nil))
      end
    else
      self.assessment_terms.build(:start_date => ac_year.try(:start_date), :end_date => ac_year.try(:end_date))
    end
  end
  
  def report_template
    report_template_name.present? ? GradebookTemplate.get_template(report_template_name) : AssessmentReportSetting.to_report_template(id)
  end
  
  def build_record_groups
    unless self.gradebook_record_groups.present?
      self.gradebook_record_groups.build(:assessment_plan_id=>self.id)
    end
  end
  
  def has_employee_privilege
    true #Todo: Change in phase 2
  end
  
  def assessment_plan_id
    self.id
  end
  
  def has_dependencies?
    if has_terms?
      assessment_terms.all(:joins => :assessment_groups).count > 0
    else
      assessment_groups.present?
    end
  end
  
  def has_dependency_for_course(course)
    ass_ids  = get_assessment_groups.collect(&:id).uniq
    agbs = course.assessment_group_batches.all(:conditions => ["assessment_group_id in (?)", ass_ids])
    has_associated_records  = agbs.map {|agb| agb.children?}
    has_associated_records.include?(true)
  end
  
  def check_term_date_ranges
    previous = nil
    assessment_terms.sort{|a, b| (a.start_date && b.start_date) ? a.start_date <=> b.start_date : (a.start_date ? -1 : 1)}.each_with_index do |term, index|
      if index > 0 and term.start_date.present? and previous.end_date.present? and term.start_date < previous.end_date
        term.errors.add(:start_date, :overlaps_with_an_term) 
        errors.add(:base, :dependencies_exist)
      end
      previous = term
    end
  end
  
  def build_courses
    courses = Course.active.all(:select => "courses.*, group_concat(if(ap.academic_year_id = #{academic_year_id}, ap.id, null)) AS planner_id, 
      group_concat(if(ap.academic_year_id = #{academic_year_id}, ap.name, null)) AS planner_name",
      :joins => "LEFT OUTER JOIN assessment_plans_courses AS apc ON apc.course_id = courses.id 
      LEFT OUTER JOIN assessment_plans AS ap ON ap.id = apc.assessment_plan_id AND ap.academic_year_id = #{academic_year_id}",
      :include => :batches, :group => "courses.id")
    course_ids = assessment_plans_courses.collect(&:course_id) 
    groups_present = has_dependencies?
    courses.each do |c|
      unless course_ids.include? c.id
        assessment_plans_courses.build(:course_id => c.id, :selected => false, 
          :name => c.full_name, :batches_count => c.batches.length, :disable => c.planner_id.present?, :planner_name => c.planner_name)
      else
        course = assessment_plans_courses.detect{|pc| pc.course_id == c.id}
        course.attributes = {:selected => true, :name => c.full_name, 
          :batches_count => c.batches.length, :disable => groups_present, :planner_name => name}
      end
    end
  end
  
  def check_courses
    assessment_plans_courses.each do |course|
      course.mark_for_destruction if (!course.new_record? and course.selected == "0")
    end
  end
  
  def assessment_groups_count
    get_assessment_groups.count
  end
  
  def get_assessment_groups
    if terms_count > 0
      assessment_terms.all(:select=>'assessment_groups.*',:joins=>:assessment_groups)
    else
      assessment_groups
    end
  end
  
  def subject_exams
    if terms_count > 0
      assessment_terms.all(:select => 'assessment_groups.*', :conditions => ['assessment_groups.type = ? and assessment_groups.is_single_mark_entry = ?','SubjectAssessmentGroup',true] , :joins => :assessment_groups)
    else
      assessment_groups.all(:conditions => ['type = ? and is_single_mark_entry = ?','SubjectAssessmentGroup', true])
    end
  end
  
  def attribute_exams
    if terms_count > 0
      assessment_terms.all(:select => 'assessment_groups.*', :conditions => ['assessment_groups.type = ? and assessment_groups.is_single_mark_entry = ?','SubjectAssessmentGroup', false] , :joins => :assessment_groups)
    else
      assessment_groups.all(:conditions => ['type = ? and is_single_mark_entry = ?','SubjectAssessmentGroup', false])
    end
  end
  
  def activity_exams
    if terms_count > 0
      assessment_terms.all(:select => 'assessment_groups.*', :conditions => ['assessment_groups.type = ?','ActivityAssessmentGroup'] , :joins => :assessment_groups)
    else
      assessment_groups.all(:conditions => ['type = ?','ActivityAssessmentGroup'])
    end
  end
  
  def derived_exams
    if terms_count > 0
      assessment_terms.all(:select => 'assessment_groups.*', :conditions => ['assessment_groups.type = ? and assessment_groups.is_final_term = ? and parent_type = ?','DerivedAssessmentGroup', false, 'AssessmentTerm'] , :joins => :assessment_groups)
    else
      assessment_groups.all(:conditions => ['type = ? and is_final_term = ? and parent_type = ?','DerivedAssessmentGroup', false, 'AssessmentPlan'])
    end
  end
  
  def has_terms?
    terms_count > 0
  end
  
  def course_students
    courses.all(:joins => {:batches => :students}, :select => 'DISTINCT students.*', :conditions => ['batches.is_active = ? and students.is_active = ?',true, true])
  end
  
  def final_assessment
    final = self.assessment_groups.first(:conditions => {:is_final_term => true}, :include => [{:assessment_group_batches => {:subject_attribute_assessments => {:attribute_assessments => :assessment_attribute}}}]) || DerivedAssessmentGroup.new(
      :parent => self,
      :scoring_type => 1,
      :assessment_plan_id => self.id,
      :academic_year_id => self.academic_year_id,
      :is_final_term => true
    )
    final.connectable_assessments = final.no_exam? ? connectable_assessments_for_no_exam : connectable_assessments
    final
  end
  
  def connectable_assessments
    AssessmentGroup.all(:conditions => ['parent_id in (?) AND parent_type = ? AND
      ((assessment_groups.type = ?) OR (assessment_groups.type = ? 
      AND assessment_groups.scoring_type in (?))) AND assessment_groups.no_exam = (?)',assessment_term_ids,
        'AssessmentTerm','DerivedAssessmentGroup','SubjectAssessmentGroup',[1,3],false], :include => :parent)
  end
  
  def connectable_assessments_for_no_exam
    AssessmentGroup.all(:conditions => ['parent_id in (?) AND parent_type = ? AND
      ((assessment_groups.type = ?) OR (assessment_groups.type = ?)) AND assessment_groups.no_exam = (?)',assessment_term_ids,
        'AssessmentTerm','DerivedAssessmentGroup','SubjectAssessmentGroup',false], :include => :parent)
  end
  
  def connectable_assessments_without_derived
    AssessmentGroup.all(:conditions => ['parent_id in (?) AND parent_type = ? AND
      (assessment_groups.type = ? AND assessment_groups.scoring_type in (?))',assessment_term_ids,
        'AssessmentTerm','SubjectAssessmentGroup',[1,3]], :include => {:assessment_group_batches => 
          [:subject_assessments, :attribute_assessments, :activity_assessments]})
  end
  
  def subject_and_derived_assessments
    AssessmentGroup.all(:conditions => ['parent_id in (?) AND parent_type = ? AND
      (assessment_groups.type <> ?)',assessment_term_ids,
        'AssessmentTerm','ActivityAssessmentGroup'])
  end
  
  
  def connectable_derived_assessments
    DerivedAssessmentGroup.all(:conditions => ['parent_id in (?) AND parent_type = ? AND
      (scoring_type in (?))',assessment_term_ids,
        'AssessmentTerm',[1,3]], :include => :derived_assessment_group_setting)
  end
  
  def plan_assessment_groups
    AssessmentGroup.all(:conditions => ['parent_id in (?) AND parent_type = ?',assessment_term_ids, 'AssessmentTerm'])
  end
  
  def course_report(course_id)
    generated_reports.first(:conditions => {:course_id => course_id})
  end
  
  def get_assessment_groups_for_report(term_ids)
    black_list_group_ids = []
    connectable_derived_assessments.each do |dag|
      black_list_group_ids += dag.assessment_group_ids  if !dag.is_final_term and !dag.show_child_in_term_report? 
    end
    black_list_group_ids << '' if black_list_group_ids.blank?
    AssessmentGroup.all(:conditions => ['parent_id in (?) AND parent_type = ? AND id NOT IN (?) AND
      (assessment_groups.type <> ?)',term_ids,'AssessmentTerm',black_list_group_ids,'ActivityAssessmentGroup'])
  end
  
  def activity_assessments(term_ids)
    ActivityAssessmentGroup.all(:conditions => ['parent_id in (?) AND parent_type = ?',term_ids, 'AssessmentTerm'],
      :include => {:assessment_group_batches => {:activity_assessments => :assessment_activity}})
  end
  
  def self.reset_batch_wise_reports( batch_report)
    plan = AssessmentPlan.find_by_id batch_report.parameters[:reportable_id]
    if plan
      batch_ids =  batch_report.parameters[:batch_ids]
      generated_report = plan.course_report(batch_report.course_id)
      generated_report_batches = generated_report.generated_report_batches.all(:conditions => {:batch_id => batch_ids})
      batch_report_ids = generated_report_batches.collect(&:batch_wise_student_report_id)
      count = GeneratedReportBatch.update_all({:batch_wise_student_report_id => batch_report.id },["id IN (?)",generated_report_batches.collect(&:id)])
      
      [count > 0 , batch_report_ids]
    end
  end
  
  def report_groups
    childrens = []
    final_ass = final_assessment
    final_ass.assessment_groups.each do |group|
      childrens += group.all_assessment_groups_for_report('planner') if group.derived_assessment? and group.show_child_in_planner_report?
      childrens << group
    end
    childrens.uniq << final_ass
  end
  
  def activity_groups
    ActivityAssessmentGroup.all(:conditions => {:assessment_plan_id => self.id}, 
      :include => {:assessment_group_batches => {:activity_assessments => :assessment_activity}})
  end
    
  def build_manual_attendance(s_id,attendance_entries)
    attendance_entries.to_a.find{|obj| obj.linkable_id == self.id and obj.linkable_type  == "planner" and obj.student_id == s_id}
  end
  
  def build_automatic_attendance(attendances,student,assessment_dates,batch,holidays)
    terms = self.assessment_terms.all(:order=>:start_date)
    leaves_total = 0
    student_academic_days = 0
    terms.each do |term|
      student_term_academic_days,term_leaves_total = Attendance.student_leaves_total(attendances,student,batch,term.start_date,term.end_date,holidays)
      student_academic_days += student_term_academic_days
      leaves_total += term_leaves_total
    end
    
    return student_academic_days,leaves_total
  end
  
  def subjectwise_attendance(student,batch,sub,assessment_date,holiday_event_dates)
    final_total = 0;final_academic_days = 0;final_percentage = 0;final_leave = 0;
    terms = self.assessment_terms.all(:order=>:start_date)
    subjectwise_attendance ={}
    sub.each do |subj| 
      leave_hash={}
      subj_total_leave = 0;subj_total_academic_year = 0;subj_total_attendance = 0;
      terms.each do |term|
        start_date = term.start_date
        end_date = term.end_date
        academic_days = batch.subject_hours(start_date, end_date, subj.obj_id, nil, nil, holiday_event_dates).values.flatten.compact.count #- cancelled_subject_periods.count
        report = SubjectLeave.find_all_by_subject_id(subj.obj_id,  :conditions =>{:batch_id=>batch.id,:month_date => start_date..end_date})
        report = report.to_a.reject{|ct| ct.attendance_label.try(:attendance_type) == "Late"}
        grouped = report.group_by(&:student_id)
        if grouped[student.id].nil?
          leave = 0
        else
          leave = grouped[student.id].count
        end
        total = (academic_days - leave)      
        subj_total_leave+= leave
        subj_total_academic_year+= academic_days
        subj_total_attendance+= total
      end 
      leave_hash={:leave=>subj_total_leave,:academic_days=>subj_total_academic_year,:total=>subj_total_attendance}
      leave_hash[:percent] = (subj_total_attendance.to_f/subj_total_academic_year)*100 unless subj_total_academic_year == 0
      subjectwise_attendance[subj.obj_id] = leave_hash
      final_total+= subj_total_attendance
      final_academic_days+= subj_total_academic_year
      final_leave+= subj_total_leave
    end
    final_percentage = (final_total.to_f/final_academic_days)*100 unless final_academic_days == 0
    final={:total=>final_total,:academic_days=>final_academic_days,:leave=>final_leave,:percent=>final_percentage}
    subjectwise_attendance[:combined] = final
    return subjectwise_attendance
  end
  
  def cumulative_subjectwise_attendance(student,batch,subjects,assessment_date,holiday_event_dates)
    cumulative_subjectwise_leave = {}
    cumulative_subjectwise_leave = subjectwise_attendance(student,batch,subjects,assessment_date,holiday_event_dates)
    return cumulative_subjectwise_leave
  end
  
  def fetch_record_data(s_id,grg,flag)
    record_data = []
    rows = []
    gradebook_record = grg.gradebook_records.to_a.find{|gr| (gr.linkable_id==self.id and gr.linkable_type==self.class.to_s)}
    if gradebook_record.present?
      record_group = gradebook_record.record_group
      records = record_group.records.to_a.select{|r| r.input_type != "attachment"}
      rows << records.count
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
    if self.inherit_from_term_exam_enabled?
      group_remarks = get_group_remarks(s_id,self.assessment_terms)
      remarks_data << group_remarks if group_remarks.flatten.present?
      term_remarks = get_term_remarks(s_id,self.assessment_terms)
      remarks_data << term_remarks if term_remarks.flatten.present?
    end
    gradebook_remarks = self.gradebook_remarks.select{|gr| gr.remarkable_type == "RemarkSet" and gr.student_id == s_id}
    gradebook_remarks.each do |remark|
      remark_set_name = remark.remarkable.name
      remarks_data << [remark_set_name, self.name, remark.remark_body] if remark.remark_body.present?
    end
    remarks_data
  end
  
  def build_or_get_remark_sets
    unless self.remark_sets.present?
      remark_sets = self.remark_sets.build
    else
      remark_sets = self.remark_sets
      exam_remark_sets = remark_sets.select{|rs| rs.target_type == 'AssessmentGroup'}
      term_remark_sets = remark_sets.select{|rs| rs.target_type == 'AssessmentTerm'}
      planner_remark_sets = remark_sets.select{|rs| rs.target_type == 'AssessmentPlan'}
    end
    return {:remark_sets => remark_sets, :exam_remark_sets => exam_remark_sets,
      :term_remark_sets => term_remark_sets, :planner_remark_sets => planner_remark_sets}
  end
  
  def update_remark_attributes(remark_set_attributes_hash)
    settings = remark_settings
    if settings[:general_remarks] == "1"
      self.update_attributes(remark_set_attributes_hash)
      update_remark_inherit_settings(settings)
      updated_remark_sets = self.reload.remark_sets
      unless updated_remark_sets.present?
        general_remark_setting = self.assessment_report_settings.detect{|s| s.setting_key == "GeneralRemarks"}
        general_remark_setting.setting_value = 0
        general_remark_setting.save
      end
    else
      update_remark_settings
      self.remark_sets.destroy_all
    end
  end
  
  def find_or_create_remark_set(target_type_rs,target_type)
    target_type_rs.each do |rs|
      r_set = RemarkSet.find_or_create_by_inherited_from_and_target_type(rs.id,target_type)
      r_set.assessment_plan_id = rs.assessment_plan_id
      r_set.name = rs.name
      r_set.target_type = target_type
      r_set.inherited_from = rs.id
      r_set.save
    end
  end
  
  def remark_settings
    settings = self.assessment_report_settings
    general_remarks = settings.detect{|s| s.setting_key == "GeneralRemarks"}
    subject_wise_remarks = settings.detect{|s| s.setting_key == "SubjectWiseRemarks"}
    exam_report_remarks = settings.detect{|s| s.setting_key == "ExamReportRemark"}
    term_report_remarks = settings.detect{|s| s.setting_key == "TermReportRemark"}
    planner_report_remarks = settings.detect{|s| s.setting_key == "PlannerReportRemark"}
    return {:general_remarks => general_remarks.setting_value, 
      :subject_wise_remarks => subject_wise_remarks.setting_value, 
      :exam_report_remarks => exam_report_remarks.setting_value, 
      :term_report_remarks => term_report_remarks.setting_value, 
      :planner_report_remarks => planner_report_remarks.setting_value}
  end
  
  def update_remark_settings
    settings = self.assessment_report_settings
    report_remark = settings.select{|s| s.setting_key == "ExamReportRemark" or 
        s.setting_key == "TermReportRemark" or s.setting_key == "PlannerReportRemark" or
        s.setting_key == "InheritRemarkFromTermExam" or s.setting_key == "InheritRemarkFromExam"}
    report_remark.each do |setting|
      setting.setting_value = 0
      setting.save
    end
  end
  
  def update_remark_inherit_settings(settings)
    if settings[:exam_report_remarks] == "0" and settings[:term_report_remarks] == "0" and settings[:planner_report_remarks] == "0"
      inherit = self.assessment_report_settings.detect{|s| s.setting_key == "GeneralRemarks"}
      inherit.setting_value = 0 
      inherit.save
    end
    if settings[:term_report_remarks] == "0"
      inherit = self.assessment_report_settings.detect{|s| s.setting_key == "InheritRemarkFromExam"}
      inherit.setting_value = 0 
      inherit.save
    end 
    if settings[:planner_report_remarks] == "0"
      inherit = self.assessment_report_settings.detect{|s| s.setting_key == "InheritRemarkFromTermExam"}
      inherit.setting_value = 0 
      inherit.save
    end
  end
  
  def get_term_remarks(s_id, terms)
    assessment_term_ids = terms.collect(&:id)
    term_grs = GradebookRemark.find_all_by_student_id_and_reportable_type_and_remarkable_type(s_id,"AssessmentTerm","RemarkSet", 
      :conditions => ["reportable_id in (?)",assessment_term_ids] ,:include => :reportable)
    gradebook_remarks_hash = term_grs.group_by(&:remarkable_id)
    remarks_data = []
    gradebook_remarks_hash.each do |k,gradebook_remarks|
      each_remark_sets = []
      gradebook_remarks.each do |remark|
        remark_set_name = remark.remarkable.name
        each_remark_sets << [remark_set_name, remark.reportable.name, remark.remark_body] if remark.remark_body.present?
      end
      remarks_data << each_remark_sets
    end
    remarks_data
  end
  def get_group_remarks(s_id,terms)
    assessment_group_ids = []
    terms.each{ |at| assessment_group_ids << at.assessment_groups.collect(&:id)}
    group_grs = GradebookRemark.find_all_by_student_id_and_reportable_type_and_remarkable_type(s_id,"AssessmentGroup","RemarkSet", 
      :conditions => ["reportable_id in (?)",assessment_group_ids.flatten] ,:include => :reportable)
    gradebook_remarks_hash = group_grs.group_by(&:remarkable_id)
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
  
  def inherit_from_term_exam_enabled?
    ars = AssessmentReportSetting.find_by_assessment_plan_id_and_setting_key(self.id,"InheritRemarkFromTermExam")
    ars.setting_value == "1"
  end
  
  def general_remark_enabled?
    ars = self.assessment_report_settings.detect{|a| a.setting_key == "GeneralRemarks"}
    ars.setting_value == "1"
  end
    
  def subject_wise_remark_enabled?
    ars = self.assessment_report_settings.detect{|a| a.setting_key == "SubjectWiseRemarks"}
    ars.setting_value == "1"
  end
  
  def exam_report_remark_enabled?
    ars = self.assessment_report_settings.detect{|a| a.setting_key == "ExamReportRemark"}
    ars.setting_value == "1"
  end
  
  def term_report_remark_enabled?
    ars = self.assessment_report_settings.detect{|a| a.setting_key == "TermReportRemark"}
    ars.setting_value == "1"
  end
  
  def planner_report_remark_enabled?
    ars = self.assessment_report_settings.detect{|a| a.setting_key == "PlannerReportRemark"}
    ars.setting_value == "1"
  end
  
  def get_remark_types(course,batch_id)
    batch = Batch.find_by_id(batch_id)
    current_user=Authorization.current_user
    remark_types = []
    remark_types << [GradebookRemark::REMARK_TYPES["RemarkSet"],"RemarkSet"] if general_remark_enabled? and (current_user.privileges.include?(Privilege.find_by_name("ManageGradebook")) or current_user.admin? or current_user.privileges.include?(Privilege.find_by_name("GradebookMarkEntry")) or course.is_tutor_and_has_batch_in_this_course_academic_year(batch.academic_year.id))
    remark_types << [GradebookRemark::REMARK_TYPES["Subject"],"Subject"] if subject_wise_remark_enabled?
    remark_types
  end
  
  def get_report_types(type)
    report_types = []
    report_types << [GradebookRemark::REPORT_TYPES["AssessmentGroup"],"AssessmentGroup"] if exam_report_remark_enabled? or type == 'Subject'
    report_types << [GradebookRemark::REPORT_TYPES["AssessmentTerm"],"AssessmentTerm"] if term_report_remark_enabled? or type == 'Subject'
    report_types << [GradebookRemark::REPORT_TYPES["AssessmentPlan"],"AssessmentPlan"] if planner_report_remark_enabled? or type == 'Subject'
    report_types
  end
  
  def reportable_type_for_attendance
    "planner"
  end
  
  def assessment_term_of_reportable
    self.assessment_terms
  end
  
  def display_name
    self.name
  end

  def round_off_size_from_settings
    @round_off_size ||= (
      settings = AssessmentReportSetting.get_multiple_settings_as_hash(AssessmentReportSetting::SCORE_ROUNDING_SETTINGS, self.id)
      if settings[:enable_rounding].to_i == 1
        settings[:rounding_size].to_i || 1
      else
        false
      end
    )
  end
  
end
