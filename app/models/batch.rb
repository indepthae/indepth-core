#Fedena
#Copyright 2011 Foradian Technologies Private Limited
#
#This product includes software developed at
#Project Fedena - http://www.projectfedena.org/
#
#Licensed under the Apache License, Version 2.0 (the "License");
#you may not use this file except in compliance with the License.
#You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
#Unless required by applicable law or agreed to in writing, software
#distributed under the License is distributed on an "AS IS" BASIS,
#WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#See the License for the specific language governing permissions and
#limitations under the License.
class Batch < ActiveRecord::Base
  extend FeeDefaultersSqlGenerator
  GRADINGTYPES = {"1"=>"GPA","2"=>"CWA","3"=>"CCE","4"=>"ICSE"}

  belongs_to :course
  belongs_to :weekday_set
  belongs_to :class_timing_set
  belongs_to :academic_year

  has_many :advance_fee_category_batches
  has_many :advance_fee_categories, :through => :advance_fee_category_batches
  has_many :students
  accepts_nested_attributes_for :students
  has_many :grouped_exam_reports
  has_many :grouped_batches
  has_many :archived_students
  has_many :grading_levels, :conditions => { :is_deleted => false }
  has_many :subjects, :conditions => { :is_deleted => false }
  has_many :employees_subjects, :through =>:subjects
  has_many :exam_groups
  has_many :fee_category , :class_name => "FinanceFeeCategory"
  has_many :elective_groups
  has_many :finance_fee_collections
  has_many :finance_transactions, :through => :students
  has_many :batch_events
  has_many :events , :through =>:batch_events
  has_many :batch_fee_discounts , :foreign_key => 'receiver_id'
  has_many :student_category_fee_discounts , :foreign_key => 'receiver_id'
  has_many :attendances
  has_many :subject_leaves
  has_many :timetable_entries
  has_many :cce_reports
  has_many :assessment_scores
  has_many :class_timings
  has_many :cce_exam_category ,:through=>:exam_groups
  has_many :fa_groups ,:through=>:subjects
  has_many :time_table_class_timings
  has_many :finance_transactions
  has_many :finance_fees
  has_many :batch_class_timing_sets
  has_many :batch_timetable_summaries
  has_many :upscale_scores
  has_many :grouped_exams
  has_many :students_subjects

  has_many :batch_students
  has_and_belongs_to_many :employees,:join_table => "batch_tutors"
  has_many :batch_tutors
  has_many :finance_fee_categories,:through=>:category_batches
  has_many :category_batches
  has_many :finance_fee_particulars
  has_many :finance_fee_collections,:through=>:fee_collection_batches, :conditions => { :is_deleted => false }
  has_many :fee_collection_batches
  has_many :fee_discounts
  has_many :icse_reports
  has_many :ia_scores
  has_many :attendance_weekday_sets
  has_many :record_batch_assignments
  has_many :record_assignments,:through=>:record_batch_assignments
  has_many :record_groups,:through=>:record_batch_assignments
  has_many :student_records
  has_many :student_coscholastic_remarks
  has_many :student_coscholastic_remark_copies
  has_many :assessment_group_batches
  has_many :assessment_groups, :through => :assessment_group_batches
  has_and_belongs_to_many :assessment_schedules
  has_many :generated_report_batches
  has_many :generated_reports, :through => :generated_report_batches
  has_many :gradebook_attendances
  has_many :gradebook_remarks
  has_many :batch_subject_groups
  has_many :master_particular_reports
  has_many :marked_attendance_records
  delegate :course_name,:section_name, :code, :to => :course
  delegate :grading_type,:icse_enabled?,:cce_enabled?, :observation_groups, :cce_weightages, :to=>:course

  validates_presence_of :name, :start_date, :end_date

  attr_accessor :job_type, :allocation_status
  attr_accessor :weekly_classes
  attr_writer :total_subject_hours
  attr_writer :subject_totals

  accepts_nested_attributes_for :attendance_weekday_sets
  accepts_nested_attributes_for :batch_class_timing_sets,:allow_destroy=>true

  named_scope :active,{ :conditions => { :is_deleted => false, :is_active => true },:joins=>:course,:select=>"`batches`.*,CONCAT(courses.code,'-',batches.name) as course_full_name",:order=>"course_full_name",:include=>:course}
  named_scope :inactive,{ :conditions => { :is_deleted => false, :is_active => false },:joins=>:course,:select=>"`batches`.*,CONCAT(courses.code,'-',batches.name) as course_full_name",:order=>"course_full_name"}
  named_scope :deleted,{:conditions => { :is_deleted => true },:joins=>:course,:select=>"`batches`.*,CONCAT(courses.code,'-',batches.name) as course_full_name",:order=>"course_full_name"}
  named_scope :usable,{:conditions => { :is_deleted => false }}
  named_scope :cce, {:select => "batches.*",:joins => :course,:conditions=>["courses.grading_type = #{GRADINGTYPES.invert["CCE"]} and batches.is_deleted=#{false} and batches.is_active=#{true}"],:order=>:code}
  named_scope :icse, {:select => "batches.*",:joins => :course,:conditions=>["courses.grading_type = #{GRADINGTYPES.invert["ICSE"]} and batches.is_deleted=#{false} and batches.is_active=#{true}"],:order=>:code}
  named_scope :with_academic_year, lambda{|aca_year_id| {:conditions => {:academic_year_id => aca_year_id, :is_deleted => false}}}
  before_update :attendance_validation
  before_update :timetable_entry_validation
  before_update :weekday_set_updation
  after_update :attendance_weekday_set_updation
  before_create :default_weekdayset_and_attendance_weekday_sets
  after_create :create_batch_class_timing_set_entry
  after_create :add_record_group_assignment

  validates_format_of :roll_number_prefix, :with => /^[A-Z0-9_-]*$/i
  validates_length_of :roll_number_prefix, :maximum => 6, :allow_blank => true
  validate :date_range_inclusion

  def date_range_inclusion
    if academic_year.present? and !self.is_deleted and self.is_active
      ay_start_date = academic_year.start_date
      ay_end_date = academic_year.end_date
      errors.add_to_base("#{t('start_date')} #{t('should_in_between_academic_year_date_range')}") unless start_date.between? ay_start_date, ay_end_date
      #      errors.add_to_base("#{t('end_date')} #{t('should_in_between_academic_year_date_range')}") unless end_date.between? ay_start_date, ay_end_date
    end
  end

  def subject_components
    components = []
    components += self.elective_groups.select{|eg| eg.batch_subject_group_id.nil? and !eg.is_deleted }
    components += self.batch_subject_groups.select{|bsg| !bsg.is_deleted }
    components += self.subjects.select{|s| s.batch_subject_group_id.nil? and s.elective_group_id.nil? and !s.is_deleted }

    components.sort_by {|child| [child.priority ? 0 : 1,child.priority || 0]}
  end

  def grouped_subjects(ids=[])
    final_subjects = []
    subs = if ids.present?
      subjects.ordered.all(:conditions=>{:no_exams => false,:is_deleted => false, :id => ids})
    else
      subjects.ordered.all(:conditions=>{:no_exams => false,:is_deleted => false})
    end
    prev = nil
    subs.each do |sub|
      if sub.batch_subject_group_id.present?
        if prev.present? and prev.batch_subject_group_id.present? and (prev.batch_subject_group_id == sub.batch_subject_group_id)
          sub_arr = final_subjects.pop
          sub_arr.push(sub)
          final_subjects.push(sub_arr)
        else
          final_subjects.push([sub])
        end
      else
        final_subjects.push(sub)
      end
      prev = sub
    end

    final_subjects
  end

  def assessment_scheduled?(assessment_group)
    type = assessment_group.exam_type
    schedule = assessment_schedules.first(:conditions=>{:assessment_group_id=>assessment_group.id})
    type.subject and schedule.present? and schedule.schedule_published?
  end

  def full_name_with_status
    "#{full_name} #{is_active? ? "" : "&#x200E;(#{t('inactive')})&#x200E;"}"
  end

  def course_subject_relation
    relation = Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
    subjects = self.subjects.select{|s| !s.is_deleted }.to_a
    course.all_course_subjects.without_graded.each do |sub|
      related_subject = subjects.find{|s| s.course_subject_id == sub.id}
      relation[sub.id] = {:cs_name => sub.name, :cs_id => sub.id, :subject_name => related_subject.try(:name), :subject_id => related_subject.try(:id), :can_unlink => (related_subject.present? ? related_subject.no_dependency_for_deletion? : false)}
    end

    relation
  end

  def unlinked_subjects
    subjects.to_a.select{|s| s.course_subject_id.nil? and s.elective_group_id.nil?}
  end

  def applicable_unlinked_subjects(course_subject)
    if course_subject.parent_type == 'CourseElectiveGroup'
      ce_group = course_subject.parent
      e_group = ce_group.elective_groups.active.find(:first, :conditions => {:batch_id => self.id}, :include => :subjects)
      if e_group.present?
        [e_group]
      else
        e_groups = self.elective_groups.active.all(:joins => :subjects , :conditions => {:subjects => {:is_deleted => false, :course_subject_id => nil}}, :group => 'elective_groups.id', :include => :subjects)
        e_groups.select{|e| !e.subjects.select{|s| s.course_subject_id.present? }.present? }
      end
    else
      unlinked_subjects
    end
  end

  def effective_students(options={:active_check=>true})
    #method returns batch students including archived students for inactive batch (Array of objects -- of both ArchivedStudent and Student class)
    #to include archived students for active batch set :active_check to false

    if self.is_active? && options[:active_check]==true
      return self.students.all(:order => Student.sort_order)
    else
      sql = ellective_student_query
      student_ids = BatchStudent.find_by_sql(sql).collect(&:id)
      former_ids = ArchivedStudent.all(:conditions => {:batch_id => self.id}).collect(&:former_id)
      students = Student.find_all_by_id(student_ids, :order => Student.sort_order) + ArchivedStudent.find_all_by_former_id(student_ids+former_ids, :order =>  ArchivedStudent.sort_order)
      #students = ArchivedStudent.find_all_by_former_id(student_ids+former_ids, :order =>  ArchivedStudent.sort_order)
      if options[:active_check]==true
        return students
      else
        active_batch_students = self.students.all(:order => Student.sort_order).to_a
        students = students.to_a
        return active_batch_students + students
      end
      #      Student.all(:joins => :batch_students, :conditions=>{:batch_students =>{:batch_id => @batch.id} }, :order => Student.sort_order)
    end
  end

  def effective_students_for_reports #Effective students with gradebook report records
    if self.is_active?
      return self.students.all(:order => Student.sort_order, :include => [:converted_assessment_marks, :subjects])
    else
      sql = ellective_student_query
      student_ids = BatchStudent.find_by_sql(sql).collect(&:id)
      former_ids = ArchivedStudent.all(:conditions => {:batch_id => self.id}).collect(&:former_id)
      Student.find_all_by_id(student_ids, :order => Student.sort_order, :include => [:converted_assessment_marks, :subjects]) +
        ArchivedStudent.find_all_by_former_id(student_ids+former_ids, :order =>  ArchivedStudent.sort_order, :include => [:converted_assessment_marks, {:students_subjects=>:subject}])
    end
  end

  def ellective_student_query
    sql = <<-SQL
       select s.id id,CONCAT_WS('',s.first_name,' ',s.last_name) full_name,s.admission_no,s.first_name,s.last_name,
        bs.roll_number roll_number from students s inner join batch_students bs on bs.student_id=s.id where bs.batch_id=#{id} UNION ALL select ars.former_id id,
        CONCAT_WS('',ars.first_name,' ',ars.last_name) full_name,ars.admission_no,ars.first_name,ars.last_name,ars.roll_number roll_number from archived_students ars where ars.batch_id=#{id}
        UNION ALL select ars1.former_id id,CONCAT_WS('',ars1.first_name,' ',ars1.last_name) full_name,ars1.admission_no,ars1.first_name,ars1.last_name,
        bs.roll_number roll_number from archived_students ars1 inner join batch_students bs on bs.student_id=ars1.former_id where bs.batch_id=#{id}

    SQL

    sql
  end

  def tte_status timetable
    # status codes
    # 0 - not eligible
    # 1 - not allocated
    # 2 - partially allocated
    # 3 - completely allocated
    # check for eligibility first
    #    ttes = self.timetable_entries.all(:conditions => {:timetable_id => timetable.id, :weekday_id => timetable.timetable_weekdays})
    ttes = self.timetable_entries.select {|x| (timetable.id == x.timetable_id and timetable.timetable_weekdays.include?(x.weekday_id)) }
    return {:eligibility_code => 0, :status_text => t('not_eligible'), :reason => t('weekday_set_not_found')} unless self.weekday_set.present? #t('not_eligible')
    class_timing_sets = self.batch_class_timing_sets.map {|x| x.class_timing_set }
    default_class_timing_sets = BatchClassTimingSet.all(:conditions=>"batch_id IS NULL", :include => {:class_timing_set => :class_timings}) unless class_timing_sets.present?
    return {:eligibility_code => 0, :status_text => t('not_eligible'), :reason => t('no_default_or_weekday_set_found')} unless self.weekday_set.weekdays.present?
    return {:eligibility_code => 0, :status_text => t('not_eligible'), :reason => t('no_default_or_weekday_set_found')} unless !default_class_timing_sets.present?
    return {:eligibility_code => 0, :status_text => t('not_eligible'), :reason => t('weekdays_not_found')} unless self.weekday_set.weekdays.present? # t('not_eligible')
    class_timing_sets = default_class_timing_sets.map {|x| x.class_timing_set }.compact unless class_timing_sets.present?
    return {:eligibility_code => 0, :status_text => t('not_eligible'), :reason => t('class_timing_sets_not_found')} unless class_timing_sets.present? # t('not_eligible')
    return {:eligibility_code => 0, :status_text => t('not_eligible'), :reason => t('class_timings_not_set_in_class_timing_sets')} unless class_timing_sets.map {|x| x.class_timings if x.class_timings}.compact.present? #t('not_eligible')
    return {:eligibility_code => 0, :status_text => t('not_eligible'), :reason => t('no_subject_or_elective_group_found')} unless (self.subjects || self.elective_groups).present? # t('not_eligible')
    # if eligible check for subject employee assignments, when no timetable entries created
    unless ttes.present?
      return {:eligibility_code => 0, :status_text => t('not_eligible'), :reason => t('no_teacher_for_some_subjects')} unless (self.subjects.present? && self.subjects.select {|x| x.employees.present? }.present? ) # t('not_eligible')
    end
    # then check for timetable entries
    entry_hours = {}
    subjects_hour_shortage = 0
    self.subjects.select{|subject| (!subject.elective_group_id.present? and !subject.is_deleted) }.each do |subject|
      #      if !subject.elective_group_id.present? and !subject.is_deleted
      tte_length = ttes.select{|y| (y.entry_id == subject.id and y.entry_type == 'Subject')}.length
      entry_hours["subject_#{subject.id}"] = subject.max_weekly_classes
      subjects_hour_shortage += 1 if subject.max_weekly_classes > tte_length
      #      end
    end

    ttes_electives = ttes.reject {|x| x.entry_type == 'Subject'}
    self.elective_groups.select{|x| !x.is_deleted }.each do |elective_group|
      #      elective_ttes_length = ttes_electives.select{|y| (y.entry_id == elective_group.id and y.entry_type == 'ElectiveGroup')}.length
      elective_ttes_length = ttes_electives.select{|y| (y.entry_id == elective_group.id)}.length
      subject_hours = elective_group.subjects.map(&:max_weekly_classes).compact
      subjects_hour_shortage +=1 if (subject_hours.present? and subject_hours.min > elective_ttes_length)
    end

    ttes.length != 0 ? (((entry_hours.values.sum) <= ttes.length and subjects_hour_shortage == 0) ? (return {:eligibility_code => 3, :status_text => t('completely_allocated')}) : (return {:eligibility_code => 2, :status_text => t('partially_allocated')})) : (return {:eligibility_code => 1, :status_text => t('not_allocated')})

  end

  def is_tutor_and_in_this_batch
    current_user=Authorization.current_user
    employee = current_user.employee_entry
    if employee.is_a_batch_tutor?
      user_ids = self.employees.collect{|e| e.user.id}
      return user_ids.include?(current_user.id)
    else
      return false
    end
  end

  def is_subject_teacher_and_in_this_batch
    current_user=Authorization.current_user
    employee = current_user.employee_entry
    if employee.subjects.present?
      user_ids = self.employees_subjects.collect{|e| Employee.find(e.employee_id).user.id}
      return user_ids.include?(current_user.id)
    else
      return false
    end
  end

  def is_tutor_in_this_batch
    current_user=Authorization.current_user
    employee = current_user.employee_entry
    if employee.is_a_batch_tutor?
      user_ids = self.employees.collect{|e| e.user.id}
      return user_ids.include?(current_user.id)
    else
      return false
    end
  end

  def is_subject_teacher_for_this_subject
    current_user=Authorization.current_user
    employee = current_user.employee_entry
    if employee.subjects.present?
      user_ids = self.employees_subjects.collect{|e| Employee.find(e.employee_id).user.id}
      return user_ids.include?(current_user.id)
    else
      return false
    end
  end

  def is_student_in_this_batch
    current_user=Authorization.current_user
    student = current_user.student_entry
    s_ids=[]
    s_ids+=self.students.collect(&:id)
    s_ids+=self.batch_students.collect(&:student_id)
    s_ids=s_ids.uniq
    if s_ids.include? student.id
      return true
    else
      return false
    end
  end

  def subject_totals
    totals = {:sum => 0, :allocations => 0}
    subjects = self.subjects.select { |x| (!x.elective_group_id.present? and !x.is_deleted) }
    elective_groups = self.elective_groups.select {|x| (x.subjects.select{|x| !x.is_deleted }.present? and !x.is_deleted)}
    totals[:sum] +=  subjects.length if subjects.present?
    totals[:sum] +=  elective_groups.length if elective_groups.present?
    subjects.map {|x| totals[:allocations] += 1 if x.employees.present? }
    elective_groups.map {|x| totals[:allocations] += 1 if (x.subjects.present? and x.subjects.select {|s| s.employees.present? }.flatten.compact.present?) } if elective_groups.present?
    return totals
  end

  def update_or_create_timetable_summary summary_hash, timetable
    batch_summary = self.batch_timetable_summaries.loaded? ? self.batch_timetable_summaries.select {|x| x.timetable_id == timetable.id}.last : self.batch_timetable_summaries.find_by_timetable_id(timetable.id)
    self.batch_timetable_summaries.create({:timetable_id => timetable.id, :timetable_summary => summary_hash}) unless batch_summary.present?
    batch_summary.update_attribute(:timetable_summary, summary_hash) if batch_summary.present?
  end

  def add_record_group_assignment
    self.course.record_assignments.all(:conditions=>{:add_for_future=>true}).each do |ra|
      RecordBatchAssignment.create(:batch_id=>self.id,:record_group_id=>ra.record_group_id,:record_assignment_id=>ra.id)
    end
  end

  def roll_number_generated?
    return Student.find(:all, :conditions => ["batch_id = ? and roll_number != ?" , self.id ,""], :select =>"roll_number").present?
  end

  def get_roll_number_prefix
    self.roll_number_prefix || self.course.roll_number_prefix
  end

  def get_roll_number_suffix
    batch_strength = self.students.count
    suffix_base = batch_strength.to_s.length
    "1".rjust(suffix_base+1, '0')
  end

  def validate
    errors.add(:start_date, :should_be_before_end_date) \
      if self.start_date > self.end_date \
      if self.start_date and self.end_date
  end


  def create_batch_class_timing_set_entry
    BatchClassTimingSet.default.each do |bcts|
      BatchClassTimingSet.create(:batch_id=>self.id,:weekday_id=>bcts.weekday_id,:class_timing_set_id=>bcts.class_timing_set_id)
    end
  end

  def default_weekdayset_and_attendance_weekday_sets
    self.weekday_set = WeekdaySet.common
    self.attendance_weekday_sets.build(:weekday_set_id=>self.weekday_set_id,:start_date=>self.start_date,:end_date=>self.end_date)
  end

  def weekly_classes
    normal_subjects = self.normal_batch_subject
    weekly_classes = (normal_subjects.present? ? normal_subjects.map(&:max_weekly_classes).sum : 0)
    elective_sub_hours = self.elective_groups.select {|x| !x.is_deleted }.map {|x| x.subjects.select {|x| !x.is_deleted }.map(&:max_weekly_classes) }.reject(&:empty?)
    weekly_classes += (elective_sub_hours.present? ? elective_sub_hours.map(&:min).sum : 0)
    weekly_classes
  end

  def asl_subject
    subjects.first(:conditions=>{:is_deleted=>false,:is_asl=>true})
  end

  def sixth_subject
    subjects.first(:conditions=>{:is_deleted=>false,:is_sixth_subject=>true}) || elective_groups.first(:conditions=>{:is_deleted=>false,:is_sixth_subject=>true})
  end

  def upscaled_students_count
    if self.is_active
      self.upscale_scores.count('distinct student_id',:joins=>:student,:conditions=>{:students=>{:batch_id=>self.id}})
    else
      self.upscale_scores.count('distinct upscale_scores.student_id',:joins=>"INNER JOIN batch_students bs on bs.student_id=upscale_scores.student_id and bs.batch_id=#{id}")
    end
  end

  def get_eligible_students_count
    get_students_eligible_for_2_sub.count + get_students_eligible_for_1_sub.count
  end

  def full_upscaled_students
    @two_sub_eligible = get_students_eligible_for_2_sub
    @one_sub_eligible = get_students_eligible_for_1_sub
    collected_ids=[]
    @two_sub_eligible.each{|e| collected_ids << e.id if e.upscale_scores.count(:conditions=>{:batch_id=>self.id})==2}
    @one_sub_eligible.each{|e| collected_ids << e.id if e.upscale_scores.count(:conditions=>{:batch_id=>self.id})==1}
    collected_ids
  end

  def get_students_eligible_for_2_sub
    config = Exam.get_sort_config
    active_students=self.students.all(:joins=>"LEFT OUTER JOIN `cce_reports` ON cce_reports.student_id = students.id and cce_reports.observable_type='Observation' LEFT OUTER JOIN `observations` ON `observations`.id = `cce_reports`.observable_id LEFT OUTER JOIN `observation_groups` ON `observation_groups`.id = `observations`.observation_group_id LEFT OUTER JOIN `cce_grade_sets` ON `cce_grade_sets`.id = `observation_groups`.cce_grade_set_id LEFT OUTER JOIN `cce_grades` ON cce_grades.cce_grade_set_id = cce_grade_sets.id and cce_grades.name = cce_reports.grade_string",:select=>"students.*,IF(cce_grades.grade_point,sum(cce_grades.grade_point),0) total_grade_point",:group=>'students.id',:order=>"#{Student.sort_order}")
    if config == "roll_number"
      past_students=Student.all(:joins=>"INNER JOIN batch_students on students.id = batch_students.student_id and batch_students.batch_id = #{id} LEFT OUTER JOIN `cce_reports` ON cce_reports.student_id = students.id and cce_reports.observable_type='Observation' LEFT OUTER JOIN `observations` ON `observations`.id = `cce_reports`.observable_id LEFT OUTER JOIN `observation_groups` ON `observation_groups`.id = `observations`.observation_group_id LEFT OUTER JOIN `cce_grade_sets` ON `cce_grade_sets`.id = `observation_groups`.cce_grade_set_id LEFT OUTER JOIN `cce_grades` ON cce_grades.cce_grade_set_id = cce_grade_sets.id and cce_grades.name = cce_reports.grade_string",:select=>"students.*,IF(cce_grades.grade_point,sum(cce_grades.grade_point),0) total_grade_point",:group=>'students.id',:order=>"soundex(batch_students.roll_number),length(batch_students.roll_number),batch_students.roll_number ASC")
    else
      past_students=Student.all(:joins=>"INNER JOIN batch_students on students.id = batch_students.student_id and batch_students.batch_id = #{id} LEFT OUTER JOIN `cce_reports` ON cce_reports.student_id = students.id and cce_reports.observable_type='Observation' LEFT OUTER JOIN `observations` ON `observations`.id = `cce_reports`.observable_id LEFT OUTER JOIN `observation_groups` ON `observation_groups`.id = `observations`.observation_group_id LEFT OUTER JOIN `cce_grade_sets` ON `cce_grade_sets`.id = `observation_groups`.cce_grade_set_id LEFT OUTER JOIN `cce_grades` ON cce_grades.cce_grade_set_id = cce_grade_sets.id and cce_grades.name = cce_reports.grade_string",:select=>"students.*,IF(cce_grades.grade_point,sum(cce_grades.grade_point),0) total_grade_point",:group=>'students.id',:order=>"#{Student.sort_order}")
    end
    students = self.is_active ? active_students : past_students
    @setting = CceReportSetting.get_multiple_settings_as_hash ["TwoSubUpscaleStart", "TwoSubUpscaleEnd"]
    new_list = students.reject{|student| student.total_grade_point.to_f < @setting[:two_sub_upscale_start].to_f or student.total_grade_point.to_f > @setting[:two_sub_upscale_end].to_f}
    new_list
  end
  def get_students_eligible_for_1_sub
    config = Exam.get_sort_config
    active_students=self.students.all(:joins=>"LEFT OUTER JOIN `cce_reports` ON cce_reports.student_id = students.id and cce_reports.observable_type='Observation' LEFT OUTER JOIN `observations` ON `observations`.id = `cce_reports`.observable_id LEFT OUTER JOIN `observation_groups` ON `observation_groups`.id = `observations`.observation_group_id LEFT OUTER JOIN `cce_grade_sets` ON `cce_grade_sets`.id = `observation_groups`.cce_grade_set_id LEFT OUTER JOIN `cce_grades` ON cce_grades.cce_grade_set_id = cce_grade_sets.id and cce_grades.name = cce_reports.grade_string",:select=>"students.*,IF(cce_grades.grade_point,sum(cce_grades.grade_point),0) total_grade_point",:group=>'students.id',:order=>"#{Student.sort_order}")
    if config == "roll_number"
      past_students=Student.all(:joins=>"INNER JOIN batch_students on students.id = batch_students.student_id and batch_students.batch_id = #{id} LEFT OUTER JOIN `cce_reports` ON cce_reports.student_id = students.id and cce_reports.observable_type='Observation' LEFT OUTER JOIN `observations` ON `observations`.id = `cce_reports`.observable_id LEFT OUTER JOIN `observation_groups` ON `observation_groups`.id = `observations`.observation_group_id LEFT OUTER JOIN `cce_grade_sets` ON `cce_grade_sets`.id = `observation_groups`.cce_grade_set_id LEFT OUTER JOIN `cce_grades` ON cce_grades.cce_grade_set_id = cce_grade_sets.id and cce_grades.name = cce_reports.grade_string",:select=>"students.*,IF(cce_grades.grade_point,sum(cce_grades.grade_point),0) total_grade_point",:group=>'students.id',:order=>"soundex(batch_students.roll_number),length(batch_students.roll_number),batch_students.roll_number ASC")
    else
      past_students=Student.all(:joins=>"INNER JOIN batch_students on students.id = batch_students.student_id and batch_students.batch_id = #{id} LEFT OUTER JOIN `cce_reports` ON cce_reports.student_id = students.id and cce_reports.observable_type='Observation' LEFT OUTER JOIN `observations` ON `observations`.id = `cce_reports`.observable_id LEFT OUTER JOIN `observation_groups` ON `observation_groups`.id = `observations`.observation_group_id LEFT OUTER JOIN `cce_grade_sets` ON `cce_grade_sets`.id = `observation_groups`.cce_grade_set_id LEFT OUTER JOIN `cce_grades` ON cce_grades.cce_grade_set_id = cce_grade_sets.id and cce_grades.name = cce_reports.grade_string",:select=>"students.*,IF(cce_grades.grade_point,sum(cce_grades.grade_point),0) total_grade_point",:group=>'students.id',:order=>"#{Student.sort_order}")
    end
    students = self.is_active ? active_students : past_students
    @setting = CceReportSetting.get_multiple_settings_as_hash ["OneSubUpscaleStart", "OneSubUpscaleEnd"]
    new_list = students.reject{|student| student.total_grade_point.to_f < @setting[:one_sub_upscale_start].to_f or student.total_grade_point.to_f > @setting[:one_sub_upscale_end].to_f}
    new_list
  end
  def get_non_eligible_students
    config = Exam.get_sort_config
    active_students=self.students.all(:joins=>"LEFT OUTER JOIN `cce_reports` ON cce_reports.student_id = students.id and cce_reports.observable_type='Observation' LEFT OUTER JOIN `observations` ON `observations`.id = `cce_reports`.observable_id LEFT OUTER JOIN `observation_groups` ON `observation_groups`.id = `observations`.observation_group_id LEFT OUTER JOIN `cce_grade_sets` ON `cce_grade_sets`.id = `observation_groups`.cce_grade_set_id LEFT OUTER JOIN `cce_grades` ON cce_grades.cce_grade_set_id = cce_grade_sets.id and cce_grades.name = cce_reports.grade_string",:select=>"students.*,IF(cce_grades.grade_point,sum(cce_grades.grade_point),0) total_grade_point",:group=>'students.id',:order=>"#{Student.sort_order}")
    if config == "roll_number"
      past_students=Student.all(:joins=>"INNER JOIN batch_students on students.id = batch_students.student_id and batch_students.batch_id = #{id} LEFT OUTER JOIN `cce_reports` ON cce_reports.student_id = students.id and cce_reports.observable_type='Observation' LEFT OUTER JOIN `observations` ON `observations`.id = `cce_reports`.observable_id LEFT OUTER JOIN `observation_groups` ON `observation_groups`.id = `observations`.observation_group_id LEFT OUTER JOIN `cce_grade_sets` ON `cce_grade_sets`.id = `observation_groups`.cce_grade_set_id LEFT OUTER JOIN `cce_grades` ON cce_grades.cce_grade_set_id = cce_grade_sets.id and cce_grades.name = cce_reports.grade_string",:select=>"students.*,IF(cce_grades.grade_point,sum(cce_grades.grade_point),0) total_grade_point",:group=>'students.id',:order=>"soundex(batch_students.roll_number),length(batch_students.roll_number),batch_students.roll_number ASC")
    else
      past_students=Student.all(:joins=>"INNER JOIN batch_students on students.id = batch_students.student_id and batch_students.batch_id = #{id} LEFT OUTER JOIN `cce_reports` ON cce_reports.student_id = students.id and cce_reports.observable_type='Observation' LEFT OUTER JOIN `observations` ON `observations`.id = `cce_reports`.observable_id LEFT OUTER JOIN `observation_groups` ON `observation_groups`.id = `observations`.observation_group_id LEFT OUTER JOIN `cce_grade_sets` ON `cce_grade_sets`.id = `observation_groups`.cce_grade_set_id LEFT OUTER JOIN `cce_grades` ON cce_grades.cce_grade_set_id = cce_grade_sets.id and cce_grades.name = cce_reports.grade_string",:select=>"students.*,IF(cce_grades.grade_point,sum(cce_grades.grade_point),0) total_grade_point",:group=>'students.id',:order=>"#{Student.sort_order}")
    end
    students = self.is_active ? active_students : past_students
    @setting = CceReportSetting.get_multiple_settings_as_hash ["OneSubUpscaleStart","TwoSubUpscaleEnd"]
    new_list = students.reject{|student| student.total_grade_point.to_f >= @setting[:one_sub_upscale_start].to_f  and student.total_grade_point.to_f <= @setting[:two_sub_upscale_end].to_f}
    new_list
  end

  def weekday_set_updation
    if ( self.start_date_changed? or self.end_date_changed? )
      last_week_day_sets=self.attendance_weekday_sets.find(:first,:conditions=>["end_date >= ? AND start_date <=?",self.start_date,self.end_date],:order=>"id DESC")
      last_week_day_sets= last_week_day_sets.present? ? last_week_day_sets : self.attendance_weekday_sets.first
      self.weekday_set_id=last_week_day_sets.weekday_set_id
    end
  end

  def attendance_weekday_set_updation
    if ( self.start_date_changed? or self.end_date_changed? )
      valid_week_day_sets=self.attendance_weekday_sets.all(:conditions=>["end_date >= ? AND start_date <=?",self.start_date,self.end_date],:order=>"id ASC")
      valid_week_day_sets=valid_week_day_sets.present? ? valid_week_day_sets : self.attendance_weekday_sets.first.to_a
      removable_week_days=self.attendance_weekday_sets.all(:conditions=>["id NOT IN (?)",valid_week_day_sets.collect(&:id)])
      first_attendance_weekday_set=valid_week_day_sets.first
      first_attendance_weekday_set.update_attributes(:start_date=>self.start_date)
      last_attendance_weekday_set=valid_week_day_sets.last
      last_attendance_weekday_set.update_attributes(:end_date=>self.end_date)
      AttendanceWeekdaySet.destroy(removable_week_days)
    end
  end

  def timetable_entry_validation
    if self.timetable_entries.present? and ( self.start_date_changed? or self.end_date_changed? )
      first_timetable_date=self.timetable_entries.find(:first,:select=>"timetables.start_date,timetables.id",:joins=>[:timetable],:order=>"timetables.start_date ASC").start_date.to_date
      last_timetable_date=self.timetable_entries.find(:first,:select=>"timetables.end_date,timetables.id",:joins=>[:timetable],:order=>"timetables.end_date DESC").end_date.to_date
      if self.start_date.to_date <=  first_timetable_date and self.end_date.to_date >= last_timetable_date
        true
      else
        if (self.end_date_changed? and self.end_date_change.each_cons(2).all? {|old_value, new_value| new_value > old_value }) and !self.start_date_changed? and self.end_date <= last_timetable_date
          true
        else
          errors.add_to_base :timetable_marked
          false
        end
      end
    else
      return true
    end
  end

  def attendance_validation
    if self.attendances.present? and ( self.start_date_changed? or self.end_date_changed? )
      first_attendance_date= self.attendances.find(:first,:order=>"month_date ASC").month_date
      last_attendance_date= self.attendances.find(:first,:order=>"month_date DESC").month_date
      if self.start_date.to_date <=  first_attendance_date and self.end_date.to_date >= last_attendance_date
        true
      else
        errors.add_to_base :attendance_marked
        false
      end
    else
      return true
    end
  end

  def is_own_profile_and_part_of_this_batch
    current_user = Authorization.current_user
    if current_user.student

    else
      return false
    end
  end

  def graduated_students
    prev_students = []
    self.batch_students.map{|bs| ((prev_students << bs.student) if bs.student) }
    prev_students
  end

  def sorted_graduated_students
    prev_students = []
    config = Configuration.find_or_create_by_config_key('StudentSortMethod')
    if config.config_value == "roll_number"
      self.batch_students.all(:order=>"soundex(batch_students.roll_number),length(batch_students.roll_number),batch_students.roll_number ASC",:include=>"student").map{|bs|(bs.student.roll_number = bs.roll_number; (prev_students << bs.student)) if bs.student }
    else
      self.batch_students.all(:include=>"student",:joins=>:student,:order=>"#{Student.sort_order}").map{|bs|(bs.student.roll_number = bs.roll_number; (prev_students << bs.student)) if bs.student }
    end
    prev_students
  end

  def full_name
    "#{code} - #{name}"
  end

  def complete_name
    "#{course_name} - #{ section_name + ' -' unless section_name.blank? } #{name}"
  end

  def course_section_name
    "#{course_name} - #{section_name}"
  end



  def inactivate
    update_attribute(:is_deleted, true)
    self.employees_subjects.destroy_all
  end

  def activate
    update_attribute(:is_deleted, false)
    update_attribute(:is_active, true)
  end

  def grading_level_list
    levels = self.grading_levels
    levels.empty? ? GradingLevel.default : levels
  end

  def fee_collection_dates
    FinanceFeeCollection.find_all_by_batch_id(self.id,:conditions => "is_deleted = false")
  end

  def all_students
    Student.find_all_by_batch_id(self.id)
  end

  def normal_batch_subject
    Subject.find_all_by_batch_id(self.id,:conditions=>["elective_group_id IS NULL AND is_deleted = false"], :include => [:timetable_entries,:exams])
  end

  def elective_batch_subject(elect_group)
    Subject.find_all_by_batch_id_and_elective_group_id(self.id,elect_group,:conditions=>["elective_group_id IS NOT NULL AND is_deleted = false"], :include => [:timetable_entries,:exams])
  end

  def all_elective_subjects
    elective_groups.map(&:subjects).compact.flatten.select{|subject| subject.is_deleted == false}
  end

  def all_subjects
    normal_subjects = Subject.find_all_by_batch_id(id,:conditions=>{:no_exams => false, :elective_group_id => nil,:is_deleted => false})
    elective_subjects = Subject.find_all_by_batch_id(id,:group=>"id",:joins=>:students_subjects,:conditions=>["no_exams = false and elective_group_id IS NOT NULL and is_deleted =false"])
    normal_subjects + elective_subjects
  end

  def all_normal_subjects
    all_subjects.select{|s| !s.is_activity }
  end

  def has_own_weekday
    weekday_set.present?
  end

  def allow_exam_acess(user)
    flag = true
    if user.employee? and user.role_symbols.include?(:subject_exam)
      flag = false if user.employee_record.subjects.all(:conditions=>"batch_id = '#{self.id}'").blank?
    end
    return flag
  end

  def is_a_holiday_for_batch?(day)
    return true if Event.holidays.count(:all, :conditions => ["start_date <=? AND end_date >= ?", day, day] ) > 0
    false
  end

  def holiday_event_dates
    @common_holidays ||= Event.holidays.is_common
    @batch_holidays=events.holidays
    all_holiday_events = @batch_holidays+@common_holidays
    event_holidays = []
    all_holiday_events.each do |event|
      event_holidays+=event.dates
    end
    return event_holidays #array of holiday event dates
  end

  def return_holidays(start_date,end_date)
    @common_holidays ||= Event.holidays.is_common
    @batch_holidays = self.events(:all,:conditions=>{:is_holiday=>true})
    all_holiday_events = @batch_holidays + @common_holidays
    all_holiday_events.reject!{|h| !(h.start_date>=start_date and h.end_date<=end_date)}
    event_holidays = []
    all_holiday_events.each do |event|
      event_holidays += event.dates
    end
    return event_holidays #array of holiday event dates
  end

  def find_working_days(start_date,end_date)
    start = []
    start << self.start_date.to_date
    start << start_date.to_date
    stop = []
    stop << self.end_date.to_date
    stop << end_date.to_date
    all_days = start.max..stop.min
    weekdays = weekday_set.nil? ? WeekdaySet.common.weekday_ids : weekday_set.weekday_ids
    holidays = return_holidays(start_date,end_date)
    non_holidays = all_days.to_a-holidays
    range = non_holidays.select{|d| weekdays.include? d.wday}
    return range
  end

  def total_days(date)
    start = []
    start << self.start_date.to_date
    start << date.beginning_of_month.to_date
    stop = []
    stop << self.end_date.to_date
    stop << date.end_of_month.to_date
    all_days = start.max..stop.min
    return all_days
  end

  def working_days(date)
    holidays = holiday_event_dates
    range=[]
    start = []
    start << self.start_date.to_date
    start << date.beginning_of_month.to_date
    stop = []
    stop << self.end_date.to_date
    stop << date.end_of_month.to_date
    total_weekday_sets=self.attendance_weekday_sets.all(:conditions=>["start_date <= ? and end_date >=? ",stop.min,start.max])
    total_weekday_sets.each do |weekdayset|
      week_day_start=[]
      week_day_end=[]
      week_day_start << weekdayset.start_date.to_date
      week_day_start << date.beginning_of_month.to_date
      week_day_end << weekdayset.end_date.to_date
      week_day_end << date.end_of_month.to_date
      weekdayset_date_range=week_day_start.max..week_day_end.min
      weekday_ids=weekdayset.weekday_set.weekday_ids
      non_holidays=weekdayset_date_range.to_a-holidays
      range << non_holidays.select{|d| weekday_ids.include? d.wday}
    end
    range=range.flatten
    return range
  end

  def updated_working_days(date)
    holidays = holiday_event_dates
    range=[]
    start = []
    start << self.start_date.to_date
    start << date.beginning_of_month.to_date
    stop = []
    stop << self.end_date.to_date
    stop << date.end_of_month.to_date
    total_weekday_sets=self.attendance_weekday_sets.all(:conditions=>["start_date <= ? and end_date >=? ",stop.min,start.max])
    total_weekday_sets.each do |weekdayset|
      week_day_start=[]
      week_day_end=[]
      week_day_start << weekdayset.start_date.to_date
      week_day_start << date.beginning_of_month.to_date
      week_day_end << weekdayset.end_date.to_date
      week_day_end << date.end_of_month.to_date
      weekdayset_date_range=week_day_start.max..week_day_end.min
      weekday_ids=weekdayset.weekday_set.weekday_ids
      non_holidays=weekdayset_date_range.to_a-holidays
      range << non_holidays.select{|d| weekday_ids.include? d.wday}
    end
    range=range.flatten
    return range
  end

  
  def date_range_working_days(start_date,end_date,total_weekday_sets=nil, holidays=nil)
    holidays = holiday_event_dates unless holidays.present?
    range=[]
    total_weekday_sets=self.attendance_weekday_sets.all(:conditions=>["start_date <= ? and end_date >=? ",end_date.to_date,start_date.to_date]) if total_weekday_sets.nil?
    total_weekday_sets.each do |weekdayset|
      week_day_start=[]
      week_day_end=[]
      week_day_start << weekdayset.start_date.to_date
      week_day_start << start_date.to_date
      week_day_end << weekdayset.end_date.to_date
      week_day_end << end_date.to_date
      weekdayset_date_range=week_day_start.max..week_day_end.min
      weekday_ids=weekdayset.weekday_set.weekday_ids
      non_holidays=weekdayset_date_range.to_a-holidays
      range << non_holidays.select{|d| weekday_ids.include? d.wday}
    end
    range=range.flatten
    return range
  end

  def academic_days
    holidays = holiday_event_dates
    range=[]
    date=Configuration.default_time_zone_present_time.to_date
    end_date_take = (end_date.to_date < date) ? end_date.to_date : date.to_date
    total_weekday_sets=self.attendance_weekday_sets.all(:conditions=>["start_date <= ? and end_date >=? ",end_date_take,self.start_date.to_date])
    total_weekday_sets.each do |weekdayset|
      week_day_start=weekdayset.start_date.to_date
      week_day_end= (weekdayset.end_date < end_date_take) ? weekdayset.end_date.to_date : end_date_take.to_date
      weekdayset_date_range=week_day_start..week_day_end
      weekday_ids=weekdayset.weekday_set.weekday_ids
      non_holidays=weekdayset_date_range.to_a-holidays
      range << non_holidays.select{|d| weekday_ids.include? d.wday}
    end
    range=range.flatten
    return range
  end
  
  def updated_academic_days
    holidays = holiday_event_dates
    range = []
    date = Configuration.default_time_zone_present_time.to_date
    end_date_take = (end_date.to_date < date) ? end_date.to_date : date.to_date
    total_weekday_sets=self.attendance_weekday_sets.all(:conditions=>["start_date <= ? and end_date >=? ",end_date_take,self.start_date.to_date])
    total_weekday_sets.each do |weekdayset|
      week_day_start=weekdayset.start_date.to_date
      week_day_end= (weekdayset.end_date < end_date_take) ? weekdayset.end_date.to_date : end_date_take.to_date
      weekdayset_date_range=week_day_start..week_day_end
      weekday_ids=weekdayset.weekday_set.weekday_ids
      non_holidays=weekdayset_date_range.to_a-holidays
      range << non_holidays.select{|d| weekday_ids.include? d.wday}
    end
    range=range.flatten
    return range
  end

  def academic_days_with_in(start_date,end_date)
    holidays = holiday_event_dates
    range=[]
    total_weekday_sets=self.attendance_weekday_sets.all(:conditions=>["start_date <= ? and end_date >=? ",end_date,start_date])
    total_weekday_sets.each do |weekdayset|
      week_day_start=weekdayset.start_date.to_date
      week_day_end= (weekdayset.end_date < end_date) ? weekdayset.end_date.to_date : end_date.to_date
      weekdayset_date_range=week_day_start..week_day_end
      weekday_ids=weekdayset.weekday_set.weekday_ids
      non_holidays=weekdayset_date_range.to_a-holidays
      range << non_holidays.select{|d| weekday_ids.include? d.wday}
    end
    range=range.flatten
    return range
  end

  def total_subject_hours(subject_id)
    days=academic_days
    count=0
    unless subject_id == 0
      subject=Subject.find subject_id
      days.each do |d|
        count=count+ Timetable.subject_tte(subject_id, d).count
      end
    else
      days.each do |d|
        count=count+ Timetable.tte_for_the_day(self,d).count
      end
    end
    count
  end

  def find_batch_rank
    @students = Student.find_all_by_batch_id(self.id, :order =>"#{Student.sort_order}")
    @grouped_exams = GroupedExam.find_all_by_batch_id(self.id)
    ordered_scores = []
    student_scores = []
    ranked_students = []
    @students.each do|student|
      score = GroupedExamReport.find_by_student_id_and_batch_id_and_score_type(student.id,student.batch_id,"c")
      marks = 0
      unless score.nil?
        marks = score.marks
      end
      ordered_scores << marks
      student_scores << [student.id,marks]
    end
    ordered_scores = ordered_scores.compact.uniq.sort.reverse
    @students.each do |student|
      marks = 0
      student_scores.each do|student_score|
        if student_score[0]==student.id
          marks = student_score[1]
        end
      end
      ranked_students << [(ordered_scores.index(marks) + 1),marks,student.id,student]
    end
    ranked_students = ranked_students.sort
  end

  def find_attendance_rank(start_date,end_date)
    attendance_lock = AttendanceSetting.is_attendance_lock
    @students = Student.find_all_by_batch_id(self.id, :order =>"#{Student.sort_order}")
    ranked_students=[]
    student_working_days=Hash.new
    unless @students.empty?
      if attendance_lock
        working_days = MarkedAttendanceRecord.dailywise_working_days(self.id)
      else
        working_days = self.find_working_days(start_date,end_date)#.count
      end
      working_days_count = working_days.count
      unless working_days == 0
        ordered_percentages = []
        student_percentages = []
        @students.each do|student|
          student_admission_date = student.admission_date
          leaves = Attendance.find(:all,:conditions=>["student_id = ? and month_date >= ? and month_date <= ?",student.id,start_date,end_date])
          leaves = leaves.to_a.select{|a| working_days.include?(a.month_date) }  if attendance_lock
          student_working_days[student.id] = Attendance.calculate_student_working_days(student_admission_date,end_date,start_date,working_days,working_days_count)
          leaves = leaves.to_a.reject{|sl| sl.attendance_label.try(:attendance_type) == "Late"}
          absents = 0
          unless leaves.empty?
            leaves.each do|leave|
              if leave.forenoon == true and leave.afternoon == true
                absents = absents + 1
              else
                absents = absents + 0.5
              end
            end
          end
          percentage = student_working_days[student.id] == 0 ? 0 : (((student_working_days[student.id] - absents).to_f/student_working_days[student.id].to_f)*100).round(2)
          ordered_percentages << percentage
          student_percentages << [student.id,(student_working_days[student.id] - absents),percentage]
        end
        ordered_percentages = ordered_percentages.compact.uniq.sort.reverse
        @students.each do |student|
          stu_percentage = 0
          attended = 0
          working_days
          student_percentages.each do|student_percentage|
            if student_percentage[0]==student.id
              attended = student_percentage[1]
              stu_percentage = student_percentage[2]
            end
          end
          ranked_students << [(ordered_percentages.index(stu_percentage) + 1),stu_percentage,student.first_name,student_working_days[student.id],attended,student, student_working_days[student.id]]
        end
      end
    end
    return ranked_students
  end

  def gpa_enabled?
    Configuration.has_gpa? and self.grading_type=="1"
  end

  def cwa_enabled?
    Configuration.has_cwa? and self.grading_type=="2"
  end

  def normal_enabled?
    self.grading_type.nil? or self.grading_type=="0"
  end

  def generate_batch_reports
    grading_type = self.grading_type
    students = self.students
    grouped_exams = self.exam_groups.reject{|e| !GroupedExam.exists?(:batch_id=>self.id, :exam_group_id=>e.id)}
    gpa_config_value = Configuration.get_config_value("CalculationMode")
    unless grouped_exams.empty?
      subjects = self.subjects(:conditions=>{:is_deleted=>false})
      unless students.empty?
        st_scores = GroupedExamReport.find_all_by_student_id_and_batch_id(students,self.id)
        unless st_scores.empty?
          st_scores.map{|sc| sc.destroy}
        end
        subject_marks=[]
        exam_marks=[]
        grouped_exams.each do|exam_group|
          subjects.each do|subject|
            exam = Exam.find_by_exam_group_id_and_subject_id(exam_group.id,subject.id)
            unless exam.nil?
              students.each do|student|
                is_assigned_elective = 1
                unless subject.elective_group_id.nil?
                  assigned = StudentsSubject.find_by_student_id_and_subject_id(student.id,subject.id)
                  if assigned.nil?
                    is_assigned_elective=0
                  end
                end
                unless is_assigned_elective==0
                  percentage = 0
                  marks = 0
                  score = ExamScore.find_by_exam_id_and_student_id(exam.id,student.id)
                  if grading_type.nil? or self.normal_enabled?
                    unless score.nil? or score.marks.nil?
                      percentage = exam.maximum_marks.to_f==0 ? 0.0 : (((score.marks.to_f)/exam.maximum_marks.to_f)*100)*((exam_group.weightage.to_f)/100)
                      marks = score.marks.to_f
                    end
                  elsif self.gpa_enabled?
                    unless score.nil? or score.grading_level_id.nil?
                      if gpa_config_value.to_i == 0 #old method of calculating
                        percentage = (score.grading_level.credit_points.to_f)*((exam_group.weightage.to_f)/100)
                      else  #weighted grade calculation mode
                        percentage = (((score.marks.to_f)/exam.maximum_marks.to_f)*100)*((exam_group.weightage.to_f)/100)
                      end
                      marks = (score.grading_level.credit_points.to_f) * (subject.credit_hours.to_f)
                    end
                  elsif self.cwa_enabled?
                    unless score.nil? or score.marks.nil?
                      percentage = exam.maximum_marks.to_f==0 ? 0.0 : (((score.marks.to_f)/exam.maximum_marks.to_f)*100)*((exam_group.weightage.to_f)/100)
                      marks = exam.maximum_marks.to_f==0 ? 0.0 : (((score.marks.to_f)/exam.maximum_marks.to_f)*100)*(subject.credit_hours.to_f)
                    end
                  end
                  flag=0
                  subject_marks.each do|s|
                    if s[0]==student.id and s[1]==subject.id
                      s[2] << percentage.to_f
                      s[3] << exam_group.weightage.to_f
                      flag=1
                    end
                  end

                  unless flag==1
                    subject_marks << [student.id,subject.id,[percentage.to_f],[exam_group.weightage.to_f]]
                  end
                  e_flag=0
                  exam_marks.each do|e|
                    if e[0]==student.id and e[1]==exam_group.id
                      e[2] << marks.to_f
                      if grading_type.nil? or self.normal_enabled?
                        e[3] << exam.maximum_marks.to_f
                      elsif self.gpa_enabled? or self.cwa_enabled?
                        e[3] << subject.credit_hours.to_f
                      end
                      e_flag = 1
                    end
                  end
                  unless e_flag==1
                    if grading_type.nil? or self.normal_enabled?
                      exam_marks << [student.id,exam_group.id,[marks.to_f],[exam.maximum_marks.to_f]]
                    elsif self.gpa_enabled? or self.cwa_enabled?
                      exam_marks << [student.id,exam_group.id,[marks.to_f],[subject.credit_hours.to_f]]
                    end
                  end
                end
              end
            end
          end
        end
        subject_marks.each do|subject_mark|
          student_id = subject_mark[0]
          subject_id = subject_mark[1]
          marks = subject_mark[2].sum.to_f
          total_weightage = subject_mark[3].sum.to_f
          unless total_weightage == 100
            marks = (marks * 100)/total_weightage
          end
          prev_marks = GroupedExamReport.find_by_student_id_and_subject_id_and_batch_id_and_score_type(student_id,subject_id,self.id,"s")
          unless prev_marks.nil?
            unless self.gpa_enabled? and gpa_config_value.to_i == 1
              prev_marks.update_attributes(:marks=>marks)
            else
              grade_record = GradingLevel.percentage_to_grade(marks, self.id)
              prev_marks.update_attributes(:percentage=>marks,:marks=>grade_record.credit_points.to_f)
            end
          else
            unless self.gpa_enabled? and gpa_config_value.to_i == 1
              GroupedExamReport.create(:batch_id=>self.id,:student_id=>student_id,:marks=>marks,:score_type=>"s",:subject_id=>subject_id)
            else
              grade_record = GradingLevel.percentage_to_grade(marks, self.id)
              GroupedExamReport.create(:batch_id=>self.id,:student_id=>student_id,:marks=>grade_record.credit_points.to_f,:score_type=>"s",:subject_id=>subject_id,
                :percentage=>marks)
            end
          end
        end
        exam_totals = []
        exam_marks.each do|exam_mark|
          student_id = exam_mark[0]
          exam_group = ExamGroup.find(exam_mark[1])
          score = exam_mark[2].sum
          max_marks = exam_mark[3].sum
          tot_score = 0
          percent = 0
          unless max_marks.to_f==0
            if grading_type.nil? or self.normal_enabled?
              tot_score = (((score.to_f)/max_marks.to_f)*100)
              percent = (((score.to_f)/max_marks.to_f)*100)*((exam_group.weightage.to_f)/100)
            elsif self.gpa_enabled? or self.cwa_enabled?
              tot_score = ((score.to_f)/max_marks.to_f)
              percent = ((score.to_f)/max_marks.to_f)*((exam_group.weightage.to_f)/100)
            end
          end
          prev_exam_score = GroupedExamReport.find_by_student_id_and_exam_group_id_and_score_type(student_id,exam_group.id,"e")
          unless prev_exam_score.nil?
            prev_exam_score.update_attributes(:marks=>tot_score)
          else
            GroupedExamReport.create(:batch_id=>self.id,:student_id=>student_id,:marks=>tot_score,:score_type=>"e",:exam_group_id=>exam_group.id)
          end
          exam_flag=0
          exam_totals.each do|total|
            if total[0]==student_id
              total[1] << percent.to_f
              exam_flag=1
            end
          end
          unless exam_flag==1
            exam_totals << [student_id,[percent.to_f]]
          end
        end
        exam_totals.each do|exam_total|
          student_id=exam_total[0]
          total=exam_total[1].sum.to_f
          prev_total_score = GroupedExamReport.find_by_student_id_and_batch_id_and_score_type(student_id,self.id,"c")
          unless prev_total_score.nil?
            prev_total_score.update_attributes(:marks=>total)
          else
            GroupedExamReport.create(:batch_id=>self.id,:student_id=>student_id,:marks=>total,:score_type=>"c")
          end
        end
      end
    end
  end

  def generate_previous_batch_reports
    grading_type = self.grading_type
    students=[]
    batch_students= BatchStudent.find_all_by_batch_id(self.id)
    batch_students.each do|bs|
      stu = Student.find_by_id(bs.student_id)
      students.push stu unless stu.nil?
    end
    grouped_exams = self.exam_groups.reject{|e| !GroupedExam.exists?(:batch_id=>self.id, :exam_group_id=>e.id)}
    gpa_config_value = Configuration.get_config_value("CalculationMode")
    unless grouped_exams.empty?
      subjects = self.subjects(:conditions=>{:is_deleted=>false})
      unless students.empty?
        st_scores = GroupedExamReport.find_all_by_student_id_and_batch_id(students,self.id)
        unless st_scores.empty?
          st_scores.map{|sc| sc.destroy}
        end
        subject_marks=[]
        exam_marks=[]
        grouped_exams.each do|exam_group|
          subjects.each do|subject|
            exam = Exam.find_by_exam_group_id_and_subject_id(exam_group.id,subject.id)
            unless exam.nil?
              students.each do|student|
                is_assigned_elective = 1
                unless subject.elective_group_id.nil?
                  assigned = StudentsSubject.find_by_student_id_and_subject_id(student.id,subject.id)
                  if assigned.nil?
                    is_assigned_elective=0
                  end
                end
                unless is_assigned_elective==0
                  percentage = 0
                  marks = 0
                  score = ExamScore.find_by_exam_id_and_student_id(exam.id,student.id)
                  if grading_type.nil? or self.normal_enabled?
                    unless score.nil? or score.marks.nil?
                      percentage = exam.maximum_marks.to_f==0 ? 0.0 : (((score.marks.to_f)/exam.maximum_marks.to_f)*100)*((exam_group.weightage.to_f)/100)
                      marks = score.marks.to_f
                    end
                  elsif self.gpa_enabled?
                    unless score.nil? or score.grading_level_id.nil?
                      if gpa_config_value.to_i == 0 #old method of calculating
                        percentage = (score.grading_level.credit_points.to_f)*((exam_group.weightage.to_f)/100)
                      else  #weighted grade calculation mode
                        percentage = (((score.marks.to_f)/exam.maximum_marks.to_f)*100)*((exam_group.weightage.to_f)/100)
                      end
                      marks = (score.grading_level.credit_points.to_f) * (subject.credit_hours.to_f)
                    end
                  elsif self.cwa_enabled?
                    unless score.nil? or score.marks.nil?
                      percentage = exam.maximum_marks.to_f==0 ? 0.0 : (((score.marks.to_f)/exam.maximum_marks.to_f)*100)*((exam_group.weightage.to_f)/100)
                      marks = exam.maximum_marks.to_f==0 ? 0.0 : (((score.marks.to_f)/exam.maximum_marks.to_f)*100)*(subject.credit_hours.to_f)
                    end
                  end
                  flag=0
                  subject_marks.each do|s|
                    if s[0]==student.id and s[1]==subject.id
                      s[2] << percentage.to_f
                      s[3] << exam_group.weightage.to_f
                      flag=1
                    end
                  end

                  unless flag==1
                    subject_marks << [student.id,subject.id,[percentage.to_f],[exam_group.weightage.to_f]]
                  end
                  e_flag=0
                  exam_marks.each do|e|
                    if e[0]==student.id and e[1]==exam_group.id
                      e[2] << marks.to_f
                      if grading_type.nil? or self.normal_enabled?
                        e[3] << exam.maximum_marks.to_f
                      elsif self.gpa_enabled? or self.cwa_enabled?
                        e[3] << subject.credit_hours.to_f
                      end
                      e_flag = 1
                    end
                  end
                  unless e_flag==1
                    if grading_type.nil? or self.normal_enabled?
                      exam_marks << [student.id,exam_group.id,[marks.to_f],[exam.maximum_marks.to_f]]
                    elsif self.gpa_enabled? or self.cwa_enabled?
                      exam_marks << [student.id,exam_group.id,[marks.to_f],[subject.credit_hours.to_f]]
                    end
                  end
                end
              end
            end
          end
        end
        subject_marks.each do|subject_mark|
          student_id = subject_mark[0]
          subject_id = subject_mark[1]
          marks = subject_mark[2].sum.to_f
          total_weightage = subject_mark[3].sum.to_f
          unless total_weightage == 100
            marks = (marks * 100)/total_weightage
          end
          prev_marks = GroupedExamReport.find_by_student_id_and_subject_id_and_batch_id_and_score_type(student_id,subject_id,self.id,"s")
          unless prev_marks.nil?
            unless self.gpa_enabled? and gpa_config_value.to_i == 1
              prev_marks.update_attributes(:marks=>marks)
            else
              grade_record = GradingLevel.percentage_to_grade(marks, self.id)
              prev_marks.update_attributes(:percentage=>marks,:marks=>grade_record.credit_points.to_f)
            end
          else
            unless self.gpa_enabled? and gpa_config_value.to_i == 1
              GroupedExamReport.create(:batch_id=>self.id,:student_id=>student_id,:marks=>marks,:score_type=>"s",:subject_id=>subject_id)
            else
              grade_record = GradingLevel.percentage_to_grade(marks, self.id)
              GroupedExamReport.create(:batch_id=>self.id,:student_id=>student_id,:marks=>grade_record.credit_points.to_f,:score_type=>"s",:subject_id=>subject_id,
                :percentage=>marks)
            end
          end
        end
        exam_totals = []
        exam_marks.each do|exam_mark|
          student_id = exam_mark[0]
          exam_group = ExamGroup.find(exam_mark[1])
          score = exam_mark[2].sum
          max_marks = exam_mark[3].sum
          if grading_type.nil? or self.normal_enabled?
            tot_score = (((score.to_f)/max_marks.to_f)*100)
            percent = (((score.to_f)/max_marks.to_f)*100)*((exam_group.weightage.to_f)/100)
          elsif self.gpa_enabled? or self.cwa_enabled?
            tot_score = ((score.to_f)/max_marks.to_f)
            percent = ((score.to_f)/max_marks.to_f)*((exam_group.weightage.to_f)/100)
          end
          prev_exam_score = GroupedExamReport.find_by_student_id_and_exam_group_id_and_score_type(student_id,exam_group.id,"e")
          unless prev_exam_score.nil?
            prev_exam_score.update_attributes(:marks=>tot_score)
          else
            GroupedExamReport.create(:batch_id=>self.id,:student_id=>student_id,:marks=>tot_score,:score_type=>"e",:exam_group_id=>exam_group.id)
          end
          exam_flag=0
          exam_totals.each do|total|
            if total[0]==student_id
              total[1] << percent.to_f
              exam_flag=1
            end
          end
          unless exam_flag==1
            exam_totals << [student_id,[percent.to_f]]
          end
        end
        exam_totals.each do|exam_total|
          student_id=exam_total[0]
          total=exam_total[1].sum.to_f
          prev_total_score = GroupedExamReport.find_by_student_id_and_batch_id_and_score_type(student_id,self.id,"c")
          unless prev_total_score.nil?
            prev_total_score.update_attributes(:marks=>total)
          else
            GroupedExamReport.create(:batch_id=>self.id,:student_id=>student_id,:marks=>total,:score_type=>"c")
          end
        end
      end
    end
  end

  def teaches_in_this_batch?
    cur_user=Authorization.current_user
    if cur_user.has_required_subjects? and cur_user.has_required_batches?
      sub_ids=cur_user.employee_record.subjects.collect(&:id)
      if cur_user.employee_record.batch_ids.include?(self.id)
        unless (self.subject_ids & sub_ids).empty?
          return true
        end
      end
    end
    return false
  end

  def has_employee_privilege
    Authorization.current_user.has_common_remark_privilege(id)
  end

  def can_view_day_wise_report?
    cur_user = Authorization.current_user
    attendance_type = Configuration.get_config_value('StudentAttendanceType')
    if cur_user.admin? or (cur_user.employee? and cur_user.privileges.map{|p| p.name}.include?('StudentAttendanceView'))
      return attendance_type == "Daily"
    else
      return (cur_user.employee_record.batch_ids.include? id and attendance_type == "Daily")
    end
  end

  def subject_hours(starting_date,ending_date,subject_id, student_rec=nil, flag=nil, holidays=nil)
    attendance_lock = AttendanceSetting.is_attendance_lock
    entries = Array.new
    timetables = Timetable.all(:select=>"distinct timetables.id, start_date, end_date", :joins=> :timetable_entries,
      :conditions => ["((? BETWEEN start_date AND end_date) OR (? BETWEEN start_date AND end_date) OR (start_date BETWEEN ? AND ?)
OR (end_date BETWEEN ? AND ?)) AND timetable_entries.batch_id = ?", starting_date, ending_date,starting_date, ending_date,starting_date, ending_date, id])

    if flag.present? and flag=="elective"
      elective_group = ElectiveGroup.find(subject_id)
      batch = elective_group.batch
      elective_group_subjects = elective_group.subjects.active
    else
      subject = Subject.find(subject_id, :include => [:batch, :elective_group]) unless subject_id == 0
      batch = subject.batch unless subject.nil? and subject_id == 0
      elective_group = subject.elective_group unless (subject.nil? and subject_id == 0)
      student_subjects = subjects.normal_subject.active if (subject.nil? and subject_id == 0)
      student_e_subjects = student_rec.is_a?(Student) ? student_rec.subjects : student_rec.elective_subjects if student_rec.present?
      elective_group_subjects = subject.present? ? (elective_group.nil? ? Array.new : elective_group.subjects.active): (student_rec.present? ? student_e_subjects : elective_groups.active.map {|x| x.subjects.active }).flatten.compact
      elective_groups = elective_group_subjects.map {|x| x.elective_group}.uniq
    end
    all_timetable_class_timings = TimeTableClassTiming.find_all_by_batch_id(id, :include => {:time_table_class_timing_sets=>{:class_timing_set=>:class_timings} })
    if flag.present? and flag=="normal"
      #all_timetable_entries = TimetableEntry.find_all_by_timetable_id_and_batch_id(timetables.map(&:id),id, :include => :entry, :joins => :subject, :conditions=>["subjects.elective_group_id IS NULL and subjects.is_deleted=false"])
      all_timetable_entries = TimetableEntry.find_all_by_timetable_id_and_batch_id(timetables.map(&:id),id, :include => :entry, :joins => "LEFT OUTER JOIN subjects on subjects.id=timetable_entries.entry_id", :conditions=>["entry_type='Subject' and subjects.elective_group_id IS NULL and subjects.is_deleted=false"])
    else
      all_timetable_entries = TimetableEntry.find_all_by_timetable_id_and_batch_id(timetables.map(&:id),id, :include => :entry)
    end
    all_timetable_swaps = TimetableSwap.find(:all, :joins => :subject, :conditions => ["subjects.batch_id = ?", (!(batch.nil? and subject_id == 0) ? batch.id : id)]) # unless batch.nil? and subject_id == 0
    #    all_timetable_swaps ||= TimetableSwap.find(:all, :joins => :subject, :conditions => ["subjects.batch_id = ?", id])
    all_cancelled_timetable_swaps = TimetableSwap.find(:all, :joins => :timetable_entry, :conditions => ["timetable_entries.batch_id = ? and is_cancelled = ?", batch.id, true])
    all_cancelled_timetable_swaps ||= TimetableSwap.find(:all, :joins => :timetable_entry, :conditions => ["timetable_entries.batch_id = ? and is_cancelled = ?", id, true])
    configuration_time = Configuration.default_time_zone_present_time.to_date
    timetables.each do |timetable|
      time_table_class_timing = all_timetable_class_timings.select{|attct| attct.timetable_id == timetable.id}.first
      class_timings=[]
      if(time_table_class_timing.present?)
        time_table_class_timing.time_table_class_timing_sets.each do |ttcts|
          class_timings += ttcts.class_timing_set.class_timings.map(&:id)
        end
        weekdays = time_table_class_timing.time_table_class_timing_sets.map(&:weekday_id)
        unless subject_id == 0
          unless elective_group.nil?
            subject = elective_group_subjects
          end
          if flag.present? and flag=="elective"
            t_entries = all_timetable_entries.select{|ate| class_timings.include? ate.class_timing_id and weekdays.include? ate.weekday_id and ate.entry_id == elective_group.id and ate.entry_type == 'ElectiveGroup' and ate.timetable_id == timetable.id}
          else
            t_entries = all_timetable_entries.select{|ate| class_timings.include? ate.class_timing_id and weekdays.include? ate.weekday_id and (subject.to_a & ate.assigned_subjects).present? and ate.timetable_id == timetable.id}
          end
        else
          t_entries = all_timetable_entries.select{|ate| class_timings.include? ate.class_timing_id and weekdays.include? ate.weekday_id and ate.timetable_id == timetable.id and (student_rec.present? ? (ate.entry_type == 'Subject' ? student_subjects.map(&:id).include?(ate.entry_id) : elective_groups.map(&:id).include?(ate.entry_id)).present? : true)}
      end
        entries.push(t_entries)
      end
    end
    timetable_entries = entries.flatten.compact.dup
    entries = entries.flatten.compact.group_by(&:timetable_id)
    timetable_ids = entries.keys
    hsh2 = Hash.new
    holidays = holiday_event_dates
    unless timetable_ids.nil?
      timetables = timetables.select{|tt| timetable_ids.include? tt.id}
      hsh = Hash.new
      entries.each do |k,val|
        hsh[k] = val.group_by(&:weekday_id)
      end
      timetables.each do |tt|
        ([starting_date,start_date.to_date,tt.start_date].max..[tt.end_date,end_date.to_date,ending_date,configuration_time].min).each do |d|
          hsh2[d] = hsh[tt.id][d.wday].to_a.dup if hsh[tt.id].present?
        end
      end
    end
    holidays.each do |h|
      hsh2.delete(h)
    end
    unless subject_id == 0 or (flag.present? and flag=="elective")
      swapped_timetable_entries = all_timetable_swaps.select{|attsws| timetable_entries.map(&:id).include? attsws.timetable_entry_id}
      subject_swapped_entries = all_timetable_swaps.select{|sse| sse.subject_id == subject_id}
      swapped_timetable_entries.each do |swapped_timetable_entry|
        hsh2[swapped_timetable_entry.date.to_date].to_a.each do |hash_entry|
          if hash_entry.subject_id != swapped_timetable_entry.subject_id and hash_entry.id == swapped_timetable_entry.timetable_entry_id
            hash_entries = hsh2[swapped_timetable_entry.date.to_date].dup
            hash_entries.delete(hash_entry)
            hsh2[swapped_timetable_entry.date.to_date] = hash_entries.dup
          end
        end
      end

      subject_swapped_entries.each do |subject_swapped_entry|
        hsh2[subject_swapped_entry.date.to_date].to_a << all_timetable_entries.select{|atte| atte.id == subject_swapped_entry.timetable_entry_id}
        hsh2[subject_swapped_entry.date.to_date].to_a.compact
      end
      if hsh2.empty? and subject_swapped_entries.present?
        subject_swapped_entries.each do |subject_swapped_entry|
          if hsh2[subject_swapped_entry.date.to_date].present?
          hsh2[subject_swapped_entry.date.to_date] << subject_swapped_entry.timetable_entry
          hsh2[subject_swapped_entry.date.to_date].uniq
          else
          hs={subject_swapped_entry.date.to_date => subject_swapped_entry.timetable_entry.to_a}
          hsh2.merge!(hs)
          end
        end
      end
    end
    all_cancelled_timetable_swap_groups = all_cancelled_timetable_swaps.group_by {|swp| swp.date} if all_cancelled_timetable_swaps.present?
    hsh2.map{|dt, ttes| hsh2[dt] = (all_cancelled_timetable_swaps.present? and all_cancelled_timetable_swap_groups[dt].present?) ? hsh2[dt].reject { |tte| all_cancelled_timetable_swap_groups[dt].map(&:timetable_entry_id).include?(tte.id) } : hsh2[dt] }
    if attendance_lock && subject_id.present? && !(subject_id == 0)
      saved_academic_days = MarkedAttendanceRecord.subject_wise_tt_working_days(batch,subject_id).select{|v| v.month_date <= ending_date and  v.month_date >= starting_date}
      hsh2.each do |date, ttes|
        if saved_academic_days.collect(&:month_date).include?(date)
          hsh2[date] = ttes.flatten.collect(&:class_timing_id).select{|x| check_save_date(date,subject_id,x).present?}
        else
          hsh2.delete(date)
        end
      end
    end
    hsh2
  end

  def check_save_date(date,subject_id,class_time)
    MarkedAttendanceRecord.find(:all, :conditions => ["batch_id = ? and attendance_type = ? and month_date =? and subject_id = ? and class_timing_id = ? ",self.id,'SubjectWise',date,subject_id,class_time])
  end
  
  def create_coscholastic_reports
    report_hash={}
    observation_groups.scoped(:include=>[{:observations=>:assessment_scores},{:cce_grade_set=>:cce_grades}]).each do |og|
      og.observations.each do |o|
        report_hash[o.id]={}
        o.assessment_scores.scoped(:conditions=>{:cce_exam_category_id=>nil,:batch_id=>id}).group_by(&:student_id).each{|k,v| report_hash[o.id][k]=(v.sum(&:grade_points)/v.count.to_f)}
        report_hash[o.id].each do |key,val|
          o.cce_reports.build(:student_id=>key, :grade_string=>og.cce_grade_set.grade_string_for(val), :batch_id=> id)
        end
        o.save
      end
    end
  end
  def to_grade(score)
    if /^[\d]+(\.[\d]+){0,1}$/ === score.to_s
      grading_level_list.to_a.find{|g| g.min_score <= score.to_f.round(2).round}.try(:name) || ""
    end
  end

  def delete_coscholastic_reports
    CceReport.delete_all({:batch_id=>id,:cce_exam_category_id=>nil})
  end

  def fa_groups
    FaGroup.all(:joins=>:subjects, :conditions=>{:subjects=>{:batch_id=>id}}).uniq
  end

  def create_scholastic_reports
    report_hash=Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
    subjects.each do |subject|
      subject.fa_groups.each do |fg|
        report_hash["config"][fg.id]["fg_max_marks"] = fg.max_marks
        if fg.criteria_formula.present?
          formula = fg.criteria_formula
        else
          if fg.fa_criterias.active.count > 1
            formula = "avg(#{fg.fa_criterias.active.collect(&:formula_key).join(',')},@#{fg.max_marks.to_i})"
          elsif fg.fa_criterias.active.count == 1
            formula = "#{fg.fa_criterias.active.first.formula_key}"
          end
        end
        report_hash["config"][fg.id]["fg_formula"] = formula
        fg.fa_criterias.active.all(:include=>:assessment_scores).each do |f|
          report_hash["config"][fg.id][f.id]["fa_max_marks"] = f.max_marks
          report_hash["config"][fg.id][f.id]["indicator"] = f.formula_key
          f.assessment_scores.scoped(:conditions=>["cce_exam_category_id IS NOT NULL AND batch_id = ? and subject_id=?",id,subject.id]).group_by(&:student_id).each do |k1,v1|
            v1.group_by(&:cce_exam_category_id).each do |k2,v2|
              v2.group_by(&:subject_id).each do |k3,v3|
                report_hash["students"][k1][k2][k3][fg.id][f.id] = (fg.di_formula == 1 ? (((v3.sum(&:grade_points)/v3.count))).to_f : ((v3.sum(&:grade_points)).to_f))
              end
            end
          end
        end
      end
    end
    config_value=Configuration.find_by_config_key("CceFaType").try(:config_value) || "1"
    report_hash["students"].each do |k,v|
      v.each do |ke,va|
        va.each do |k1,v1|
          v1.each do |k2,v2|
            fa_obtained_score_hash={}
            fa_max_score_hash={}
            if config_value=="1"
              v2.each do |k3,v3|
                hsh1={report_hash["config"][k2][k3]["indicator"]=>(v3.to_f)}
                fa_obtained_score_hash.merge!hsh1
              end
            else
              v2.each do |k3,v3|
                hsh1={report_hash["config"][k2][k3]["indicator"]=>(v3.to_f/report_hash["config"][k2][k3]["fa_max_marks"].to_f)}
                fa_obtained_score_hash.merge!hsh1
              end
            end
            if config_value == "1"
              v2.each do |k3,v3|
                hsh2={report_hash["config"][k2][k3]["indicator"]=>(report_hash["config"][k2][k3]["fa_max_marks"].to_f)}
                fa_max_score_hash.merge!hsh2
              end
            else
              v2.each do |k3,v3|
                hsh2={report_hash["config"][k2][k3]["indicator"]=>1}
                fa_max_score_hash.merge!hsh2
              end
            end
            config = config_value == "1" ? :tmm : :cdm
            if (ExamFormula::formula_validate(report_hash["config"][k2]["fg_formula"], config_value) == true)
              equation = ExamFormula.new(report_hash["config"][k2]["fg_formula"],:obtained_marks=>fa_obtained_score_hash,:max_marks=>fa_max_score_hash,:mode=>config)
              if equation.valid?
                result = equation.calculate
                fa_group=FaGroup.find_by_id(k2)
                converted_mark=result.into(100)
                obtained_mark=result.into(report_hash["config"][k2]["fg_max_marks"].to_f)
                grade_string=to_grade(converted_mark)
                exam=Exam.first(:conditions=>{:exam_groups=>{:batch_id=>id,:cce_exam_category_id=>ke},:subject_id=>k1},:joins=>:exam_group)
                unless exam.nil?
                  #fa_group.cce_reports.create(:student_id=>k, :grade_string=>grade_string,:exam_id=>exam.id, :batch_id=> id,:obtained_mark=>obtained_mark.to_f,:converted_mark=>converted_mark.to_f,:max_mark=>report_hash["config"][k2]["fg_max_marks"].to_f)
                  fa_group.cce_reports.create(:student_id=>k, :grade_string=>grade_string,:exam_id=>exam.id, :batch_id=> id,:obtained_mark=>obtained_mark.to_f,:converted_mark=>converted_mark.to_f,:max_mark=>report_hash["config"][k2]["fg_max_marks"].to_f,:subject_id=>k1,:cce_exam_category_id=>ke)
                else
                  fa_group.cce_reports.create(:student_id=>k, :grade_string=>grade_string,:exam_id=>'', :batch_id=> id,:obtained_mark=>obtained_mark.to_f,:converted_mark=>converted_mark.to_f,:max_mark=>report_hash["config"][k2]["fg_max_marks"].to_f,:subject_id=>k1,:cce_exam_category_id=>ke)
                end
              else
                fa_group=FaGroup.find_by_id(k2)
                converted_mark=obtained_mark=0.0
                grade_string=to_grade(converted_mark)
                exam=Exam.first(:conditions=>{:exam_groups=>{:batch_id=>id,:cce_exam_category_id=>ke},:subject_id=>k1},:joins=>:exam_group)
                unless exam.nil?
                  #fa_group.cce_reports.create(:student_id=>k, :grade_string=>grade_string,:exam_id=>exam.id, :batch_id=> id,:obtained_mark=>obtained_mark.to_f,:converted_mark=>converted_mark.to_f,:max_mark=>report_hash["config"][k2]["fg_max_marks"].to_f)
                  fa_group.cce_reports.create(:student_id=>k, :grade_string=>grade_string,:exam_id=>exam.id, :batch_id=> id,:obtained_mark=>obtained_mark.to_f,:converted_mark=>converted_mark.to_f,:max_mark=>report_hash["config"][k2]["fg_max_marks"].to_f,:subject_id=>k1,:cce_exam_category_id=>ke)
                else
                  a = fa_group.cce_reports.build(:student_id=>k, :grade_string=>grade_string,:batch_id=> id,:obtained_mark=>obtained_mark.to_f,:converted_mark=>converted_mark.to_f,:max_mark=>report_hash["config"][k2]["fg_max_marks"].to_f,:subject_id=>k1,:cce_exam_category_id=>ke)
                  a.save
                end
              end
            else
              fa_group=FaGroup.find_by_id(k2)
              converted_mark=0.0
              obtained_mark=0.0
              grade_string=to_grade(converted_mark)
              exam=Exam.first(:conditions=>{:exam_groups=>{:batch_id=>id,:cce_exam_category_id=>ke},:subject_id=>k1},:joins=>:exam_group)
              unless exam.nil?
                #fa_group.cce_reports.create(:student_id=>k, :grade_string=>grade_string,:exam_id=>exam.id, :batch_id=> id,:obtained_mark=>obtained_mark.to_f,:converted_mark=>converted_mark.to_f,:max_mark=>report_hash["config"][k2]["fg_max_marks"].to_f)
                fa_group.cce_reports.create(:student_id=>k, :grade_string=>grade_string,:exam_id=>exam.id, :batch_id=> id,:obtained_mark=>obtained_mark.to_f,:converted_mark=>converted_mark.to_f,:max_mark=>report_hash["config"][k2]["fg_max_marks"].to_f,:subject_id=>k1,:cce_exam_category_id=>ke)
              else
                fa_group.cce_reports.create(:student_id=>k, :grade_string=>grade_string,:exam_id=>'', :batch_id=> id,:obtained_mark=>obtained_mark.to_f,:converted_mark=>converted_mark.to_f,:max_mark=>report_hash["config"][k2]["fg_max_marks"].to_f,:subject_id=>k1,:cce_exam_category_id=>ke)
              end
            end
          end
        end
      end
    end
  end

  def delete_scholastic_reports
    CceReport.delete_all(["batch_id = ? AND cce_exam_category_id > 0", id])
  end

  def delete_cce_report_setting_copy
    CceReportSettingCopy.delete_all(["batch_id = ?",id])
  end

  def generate_general_settings_copy
    general_settings = ["ReportHeader", "Attendance","AffiliationNo","NormalReportHeader", "HeaderSpace", "StudentDetail1",
      "StudentDetail2", "StudentDetail3", "StudentDetail4", "StudentDetail5", "StudentDetail6", "StudentDetail7", "StudentDetail8", "GradingLevel",
      "GradingLevelPosition", "Signature", "SignLeftText", "SignCenterText", "SignRightText","LastPage","RegistrationNo","RegistrationFieldId"]
    general_settings.each do |gs|
      setting=CceReportSetting.find_by_setting_key(gs)
      unless setting
        setting_value = CceReportSetting::FALLBACK_SETTINGS[gs]
      else
        setting_value = setting.setting_value
      end
      CceReportSettingCopy.create(:student_id=>'',:batch_id=>id,:setting_key=>gs,:data=>setting_value)
    end
  end

  def generate_health_status_settings_copy
    other_settings_1 = ["Height", "Weight", "BloodGroup", "VisionLeft", "VisionRight", "DentalHygiene"]
    hs=CceReportSetting.find_by_setting_key('HealthStatus')
    unless hs
      hs_setting_value = CceReportSetting::FALLBACK_SETTINGS['HealthStatus']
    else
      hs_setting_value = hs.setting_value
    end
    (self.is_active ? students : graduated_students).each do |s|
      other_settings_1.each do |os|
        setting=CceReportSetting.find_by_setting_key(os)
        unless setting
          setting_value = CceReportSetting::FALLBACK_SETTINGS[os]
        else
          setting_value = setting.setting_value
        end
        if hs_setting_value != "" and setting_value != "" and RecordGroup.find_by_id(hs_setting_value).present? and RecordGroup.find_by_id(hs_setting_value).records.collect(&:id).include?(setting_value.to_i)
          data=StudentRecord.first(:conditions=>{:student_id=>s.id,:batch_id=>id,:additional_field_id=>setting_value})
          CceReportSettingCopy.create(:student_id=>s.id,:batch_id=>id,:setting_key=>os,:data=>data.present? ? data.additional_info : '')
        else
          CceReportSettingCopy.create(:student_id=>s.id,:batch_id=>id,:setting_key=>os,:data=>'')
        end
      end
    end
  end

  def generate_self_awareness_settings_copy
    other_settings_2 = ["MyGoals", "MyStrengths", "InterestHobbies", "Responsibility"]
    sa=CceReportSetting.find_by_setting_key('SelfAwareness')
    unless sa
      sa_setting_value = CceReportSetting::FALLBACK_SETTINGS['SelfAwareness']
    else
      sa_setting_value = sa.setting_value
    end
    (self.is_active ? students : graduated_students).each do |s|
      other_settings_2.each do |os|
        setting=CceReportSetting.find_by_setting_key(os)
        unless setting
          setting_value = CceReportSetting::FALLBACK_SETTINGS[os]
        else
          setting_value = setting.setting_value
        end
        if sa_setting_value != "" and setting_value != "" and RecordGroup.find_by_id(sa_setting_value).present? and RecordGroup.find_by_id(sa_setting_value).records.collect(&:id).include?(setting_value.to_i)
          data=StudentRecord.first(:conditions=>{:student_id=>s.id,:batch_id=>id,:additional_field_id=>setting_value})
          CceReportSettingCopy.create(:student_id=>s.id,:batch_id=>id,:setting_key=>os,:data=>data.present? ? data.additional_info : '')
        else
          CceReportSettingCopy.create(:student_id=>s.id,:batch_id=>id,:setting_key=>os,:data=>'')
        end
      end
    end
  end

  def generate_eiop_settings_copy
    eiop_setting=EiopSetting.find_by_course_id(self.course_id)
    if eiop_setting.present?
      CceReportSettingCopy.create(:student_id=>'',:batch_id=>id,:setting_key=>'grade',:data=>(eiop_setting.grade_point == "" ? CceReportSetting::FALLBACK_SETTINGS["grade"] : eiop_setting.grade_point))
      CceReportSettingCopy.create(:student_id=>'',:batch_id=>id,:setting_key=>'pass_text',:data=>(eiop_setting.pass_text == "" ? CceReportSetting::FALLBACK_SETTINGS["pass_text"] : eiop_setting.pass_text))
      CceReportSettingCopy.create(:student_id=>'',:batch_id=>id,:setting_key=>'eiop_text',:data=>(eiop_setting.eiop_text == "" ? CceReportSetting::FALLBACK_SETTINGS["eiop_text"] : eiop_setting.eiop_text))
    end
  end

  def generate_registration_no_copy
    keys = CceReportSetting.get_multiple_settings_as_hash(["RegistrationNo","RegistrationNoVal"])
    if keys[:registration_no] == "1" and keys[:registration_no_val].present? and keys[:registration_no_val].to_i > 0
      student_list = (self.is_active ? students : graduated_students)
      student_details = StudentAdditionalDetail.all(:conditions=>{:student_id=>student_list.collect(&:id),:additional_field_id=>keys[:registration_no_val].to_i,:student_additional_fields=>{:status=>true}}, :joins=>:student_additional_field)
      student_list.each do |s|
        reg_no = student_details.find{|sd| sd.student_id == s.id}.try(:additional_info)
        CceReportSettingCopy.create(:student_id=>s.id,:batch_id=>id,:setting_key=>"RegistrationNoVal",:data=>reg_no)
      end
    end
  end

  def create_cce_report_setting_copy
    generate_general_settings_copy
    generate_registration_no_copy
    generate_health_status_settings_copy
    generate_self_awareness_settings_copy
    generate_eiop_settings_copy
  end

  def update_asl_scores
    if self.asl_subject.present?
      (self.is_active ? self.students : self.graduated_students).each do |s|
        AslScore.all(:conditions=>["subjects.batch_id = ? and subjects.id <>  ?",id,self.asl_subject.id],:joins=>{:exam=>:subject}).each do |e|
          e.destroy
        end
        s.asl_scores.all(:conditions=>{:exam=>{:subjects=>{:batch_id=>id}}},:joins=>{:exam=>:subject},:readonly=>false).each do |asl_score|
          sub= asl_score.exam.subject
          conversion=sub.asl_mark
          case conversion
          when 20
            final_score = ((asl_score.speaking.to_f + asl_score.listening.to_f)/2) * 5
            asl_score.update_attribute('final_score',final_score)
          when 10
            final_score = ((asl_score.speaking.to_f + asl_score.listening.to_f)/4) * 10
            asl_score.update_attribute('final_score',final_score)
          end
        end
      end
    else
      AslScore.all(:conditions=>{:exam=>{:subjects=>{:batch_id=>id}}},:joins=>{:exam=>:subject}).each do |e|
        e.destroy
      end
    end
  end

  def delete_upscaled_values
    self.upscale_scores.destroy_all
  end

  def delete_student_coscholastic_remarks_copy
    student_coscholastic_remark_copies.all.each do |e|
      e.destroy
    end
  end

  def create_student_coscholastic_remarks_copy
    orm = CceReportSetting.get_setting_value('ObservationRemarkMode')
    if orm == "0"
      (self.is_active ? students : graduated_students).each do |s|
        sscr = s.student_coscholastic_remarks.all(:conditions=>{:batch_id=>id})
        if sscr.present?
          sscr.each do |entry|
            StudentCoscholasticRemarkCopy.create(:student_id=>entry.student_id,:batch_id=>entry.batch_id,:observation_id=>entry.observation_id,:remark=>entry.remark)
          end
        end
      end
    else
      (self.is_active ? students : graduated_students).each do |s|
        ob_ids = s.cce_reports.coscholastic.collect(&:observable_id).uniq
        if ob_ids.present?
          Observation.find_all_by_id(ob_ids).each do |observation|
            limit=observation.observation_group.di_count_in_report
            dis=DescriptiveIndicator.co_scholastic.all(:joins=>["INNER JOIN assessment_scores ass on ass.descriptive_indicator_id=descriptive_indicators.id"],:conditions=>["ass.batch_id =? and ass.student_id=? and descriptive_indicators.describable_id=?",id,s.id,observation.id],:order=>"ass.grade_points DESC,descriptive_indicators.sort_order ASC",:limit=>limit)
            remark = dis.collect(&:name).join(', ')
            StudentCoscholasticRemarkCopy.create(:student_id=>s.id,:batch_id=>id,:observation_id=>observation.id,:remark=>remark)
          end
        end
      end
    end
  end


  def generate_cce_reports
    CceReport.transaction do
      delete_cce_report_setting_copy
      create_cce_report_setting_copy
      delete_upscaled_values
      delete_scholastic_reports
      create_scholastic_reports
      delete_coscholastic_reports
      create_coscholastic_reports
      delete_student_coscholastic_remarks_copy
      create_student_coscholastic_remarks_copy
      update_asl_scores
    end
  end

  def delete_icse_reports
    self.icse_reports.destroy_all
  end

  def generate_icse_reports
    self.exam_groups.all(:joins=>:icse_exam_category,:include=>{:exams=>[:exam_scores,:ia_scores]}).each do |exam_group|
      exam_group.exams.each do |exam|
        exam_scores=exam.exam_scores
        ia_group_ids = exam.subject.ia_groups.collect(&:id)
        ia_scores=exam.ia_scores.all(:select=>"ia_scores.mark,ia_groups.id as ia_group_id,ia_indicators.indicator,ia_indicators.max_mark,ia_calculations.formula,ia_scores.student_id,ia_scores.exam_id",:joins=>[:ia_indicator=>{:ia_group=>:ia_calculation}], :conditions=>["ia_groups.id IN (?)",ia_group_ids])
        only_ia_score_student_ids=(ia_scores.collect(&:student_id).uniq)-(exam_scores.collect(&:student_id))
        exam_scores.each do |student_score|
          student_ia_scores=ia_scores.select{|s| s.student_id==student_score.student_id}
          ia_mark=ia_mark_calculation(student_ia_scores)
          weightage=student_score.exam.subject.icse_weightages.find_by_icse_exam_category_id(exam_group.icse_exam_category_id)
          if student_score.marks.present?
            ea_float = 100/student_score.exam.maximum_marks.to_f
            ea_mark=student_score.marks*ea_float.to_f
            weightage_float = weightage.ea_weightage/100.to_f if weightage.present?
            weightage_ea=weightage.present? ? (ea_mark*weightage_float).to_f.round : 0
          end
          weightage_ia=weightage.present?? (ia_mark/100)*weightage.ia_weightage : 0
          total_mark=(weightage_ea.to_f.round)+(weightage_ia.to_f.round)
          final_ia_score = student_ia_scores.present? ? (ia_mark.to_f.round) : nil
          final_weightage_ia = student_ia_scores.present? ? (weightage_ia.to_f.round) : nil
          IcseReport.create("batch_id"=>self.id, "ea_score"=>ea_mark, "total_score"=>total_mark.to_f.round, "exam_id"=>exam.id, "ia_score"=>final_ia_score, "student_id"=>student_score.student_id,"ia_mark"=> final_weightage_ia,"ea_mark"=>weightage_ea)
        end
        if only_ia_score_student_ids.present?
          only_ia_score_student_ids.each do |student_id|
            student_ia_scores=ia_scores.select{|s| s.student_id==student_id}
            ia_mark=ia_mark_calculation(student_ia_scores)
            weightage=exam.subject.icse_weightages.find_by_icse_exam_category_id(exam_group.icse_exam_category_id)
            weightage_ia=weightage.present?? (ia_mark/100)*weightage.ia_weightage : 0
            if weightage.is_co_curricular?
              total_mark=weightage_ia.to_f.round
            end
            IcseReport.create("batch_id"=>self.id, "exam_id"=>exam.id, "ia_score"=>ia_mark.to_f.round, "student_id"=>student_id,"ia_mark"=> weightage_ia.to_f.round,"total_score"=>total_mark)
          end
        end
      end
    end
  end

  def ia_mark_calculation(ia_scores)
    ia_formula=ia_scores.collect(&:formula).uniq.first
    #obtained  score calculation
    config_value=Configuration.find_by_config_key("IcseIaType").try(:config_value)
    if ia_formula.present?
      ia_obtained_score_hash={}
      if config_value=="1"
        ia_scores.group_by(&:indicator).each do |indicator,mark|
          hsh={indicator=>(mark[0].mark.to_f)}
          ia_obtained_score_hash.merge!hsh
        end
      else
        ia_scores.group_by(&:indicator).each do |indicator,mark|
          hsh={indicator=>(mark[0].mark.to_f/mark[0].max_mark.to_f)}
          ia_obtained_score_hash.merge!hsh
        end
      end

      #maximum mark calculation
      ia_max_score_hash={}

      if config_value=="1"
        ia_scores.group_by(&:indicator).each do |indicator,mark|
          hsh={indicator=>mark[0].max_mark.to_f}
          ia_max_score_hash.merge!hsh
        end
      else
        ia_scores.group_by(&:indicator).each do |indicator,mark|
          hsh={indicator=>1}
          ia_max_score_hash.merge!hsh
        end
      end

      config = config_value == "1" ? :tmm : :cdm
      if ExamFormula::formula_validate(ia_formula, config_value)
        equation = ExamFormula.new(ia_formula,:obtained_marks=>ia_obtained_score_hash,:max_marks=>ia_max_score_hash,:mode=>config)
        if equation.valid?
          result = equation.calculate
          ia_mark = result.into(100)
        else
          ia_mark = 0
        end
      else
        ia_mark=0
      end
    else
      ia_mark=0
    end
    return ia_mark
  end

  def avg(*args)
    count=args.length
    total=0
    args.each{|s| total+=s.to_f}
    return (total.to_f/count.to_f)
  end


  def best(*args)
    count=args[0]
    scores=args-args[0].to_a
    order=scores.sort_by{|d| d.to_f}.reverse
    values=order[0..(count-1)]
    total=0
    values.each{|s| total+=s.to_f}
    if Configuration.find_by_config_key("IcseIaType").try(:config_value)=="1"
      return (total)
    else
      return (total/count)
    end
  end

  def generate_icse_exam_reports
    IcseReport.transaction do
      delete_icse_report_setting_copy
      create_icse_report_setting_copy
      delete_icse_reports
      generate_icse_reports
    end
  end

  def delete_icse_report_setting_copy
    IcseReportSettingCopy.delete_all(["batch_id = ?",id])
  end

  def create_icse_report_setting_copy
    general_settings = IcseReportSetting::SETTINGS
    general_settings.each do |gs|
      setting=IcseReportSetting.find_by_setting_key(gs)
      unless setting
        setting_value = IcseReportSetting::FALLBACK_SETTINGS[gs]
      else
        setting_value = setting.setting_value
      end
      IcseReportSettingCopy.create(:batch_id=>id,:setting_key=>gs,:data=>setting_value)
    end
  end

  def perform
    #this is for cce_report_generation use flags if need job for other works

    if job_type=="1"
      generate_batch_reports
    elsif job_type=="2"
      generate_previous_batch_reports
    elsif job_type=="4"
      generate_icse_exam_reports
    end
    prev_record = Configuration.find_by_config_key("job/Batch/#{self.job_type}")
    if prev_record.present?
      prev_record.update_attributes(:config_value=>Time.now)
    else
      Configuration.create(:config_key=>"job/Batch/#{self.job_type}", :config_value=>Time.now)
    end
  end

  def delete_student_cce_report_cache
    (self.is_active ? students : graduated_students).each do |s|
      s.batch_in_context_id = id
      s.delete_individual_cce_report_cache
    end
  end

  def check_credit_points
    grading_level_list.select{|g| g.credit_points.nil?}.empty?
  end

  def user_is_authorized?(u)
    employees.collect(&:user_id).include? u.id
  end

  def self.batch_details(parameters)
    sort_order=parameters[:sort_order]
    if sort_order.nil?
      batches=Batch.all(:select=>"batches.id,name,start_date,end_date,count(IF(students.gender like '%m%',1,NULL)) as male_count,count(IF(students.gender like '%f%',1,NULL)) as female_count,course_id,courses.code,count(students.id) as student_count",:joins=>"LEFT OUTER JOIN `students` ON students.batch_id = batches.id LEFT OUTER JOIN `courses` ON `courses`.id = `batches`.course_id",:group=>'batches.id',:conditions=>{:is_deleted=>false,:is_active=>true},:include=>[:course,:employees],:order=>'code ASC')
    else
      batches=Batch.all(:select=>"batches.id,name,start_date,end_date,count(IF(students.gender like '%m%',1,NULL)) as male_count,count(IF(students.gender like '%f%',1,NULL)) as female_count,course_id,courses.code,count(students.id) as student_count",:joins=>"LEFT OUTER JOIN `students` ON students.batch_id = batches.id LEFT OUTER JOIN `courses` ON `courses`.id = `batches`.course_id",:group=>'batches.id',:conditions=>{:is_deleted=>false,:is_active=>true},:include=>[:course,:employees],:order=>sort_order)
    end
    data=[]
    col_heads=["#{t('no_text')}","#{t('name')}","#{t('start_date')}","#{t('end_date')}","#{t('tutor')}","#{t('students')}","#{t('male')}","#{t('female')}"]
    data << col_heads
    batches.each_with_index do |obj,i|
      col=[]
      col<< "#{i+1}"
      col<< "#{obj.code}-#{obj.name}"
      col<< "#{format_date(obj.start_date.to_date)}"
      col<< "#{format_date(obj.end_date.to_date)}"
      col << "#{obj.employees.map{|em| "#{em.full_name} ( #{em.employee_number})"}.join("\n ")}"
      col<< "#{obj.student_count}"
      col<< "#{obj.male_count}"
      col<< "#{obj.female_count}"
      col=col.flatten
      data<< col
    end
    return data
  end

  def self.batch_fee_defaulters(parameters)

    sort_order=parameters[:sort_order]||nil
    course_id=parameters[:course_id]
    batches=Batch.all(:select=>"batches.id,batches.course_id,batches.name,batches.start_date,batches.end_date,sum(balance) balance,count(DISTINCT collection_id) fee_collections_count",:joins=>"INNER JOIN #{derived_sql_table} finance on finance.batch_id=batches.id",:group=>'batches.id',:include=>:course,:conditions=>{:course_id=>course_id},:order=>sort_order)
    employees=Employee.all(:select=>'batches.id as batch_id,employees.first_name,employees.last_name,employees.middle_name,employees.id as employee_id,employees.employee_number',:conditions=>{:batches=>{:course_id=>course_id}} ,:joins=>[:batches]).group_by(&:batch_id)
    data=[]
    col_heads=["#{t('no_text')}","#{t('name')}","#{t('start_date')}","#{t('end_date')}","#{t('tutor')}","#{t('fee_collections')}","#{t('balance')}(#{Configuration.currency})"]
    data << col_heads
    total = 0
    batches.each_with_index do |b,i|
      col=[]
      col<< "#{i+1}"
      col<< "#{b.code}-#{b.name}"
      col<< "#{format_date(b.start_date.to_date)}"
      col<< "#{format_date(b.end_date.to_date)}"
      unless employees.blank?
        unless employees[b.id.to_s].nil?
          emp=[]
          employees[b.id.to_s].each do |em|
            emp << "#{em.full_name} ( #{em.employee_number} )"
          end
          col << "#{emp.join("\n")}"
        else
          col << "--"
        end
      else
        col << "--"
      end
      col<< "#{b.fee_collections_count}"
      balance = b.balance.nil?? 0 : b.balance
      total += balance.to_f
      col<< "#{balance}"
      col=col.flatten
      data<< col
    end
    data << ["#{t('total_amount')}","","","","","",total]
    return data
  end

  def validate_students(students_admission_no)
    all_admission_nos=students.collect(&:admission_no)
    rejected_admission_no=students_admission_no-all_admission_nos
    return rejected_admission_no
  end
  def name_for_particular_wise_discount
    " &#x200E;(#{full_name})&#x200E;"
  end

  def fetch_activities_summary(date)
    @date=date
    first_day = @date.beginning_of_day
    last_day = @date.end_of_day
    @calender_events=[]
    #        events section==================================================
    common_event = Event.find_all_by_is_common_and_is_holiday(true,false, :conditions => ["(start_date BETWEEN ? AND ?) or (end_date BETWEEN ? AND ?) or (? BETWEEN start_date AND end_date) or (? BETWEEN start_date AND end_date)",first_day,last_day,first_day,last_day,first_day,last_day])
    @common_event_array = []
    common_event.each do |h|
      if h.start_date.to_date == h.end_date.to_date
        @common_event_array.push h if h.start_date.to_date == @date
      else
        (h.start_date.to_date..h.end_date.to_date).each do |d|
          @common_event_array.push h if d == @date
        end
      end
    end
    non_common_events = Event.find_all_by_is_common_and_is_holiday_and_is_exam_and_is_due(false,false,false,false, :conditions => ["(start_date BETWEEN ? AND ?) or (end_date BETWEEN ? AND ?) or (? BETWEEN start_date AND end_date) or (? BETWEEN start_date AND end_date)",first_day,last_day,first_day,last_day,first_day,last_day],:include=>[:batch_events])
    @student_batch_not_common_event_array = []
    non_common_events.each do |h|
      if h.start_date.to_date == "#{h.end_date.year}-#{h.end_date.month}-#{h.end_date.day}".to_date
        if "#{h.start_date.year}-#{h.start_date.month}-#{h.start_date.day}".to_date == @date
          @student_batch_not_common_event_array.push(h) if h.batch_events.collect(&:batch_id).include?(self.id)
        end
      else
        (h.start_date.to_date..h.end_date.to_date).each do |d|
          if d == @date
            @student_batch_not_common_event_array.push(h) if h.batch_events.collect(&:batch_id).include?(self.id)
          end
        end
      end
    end
    @calender_events += @common_event_array + @student_batch_not_common_event_array
    #=================================================================================================================
    #Holiday Events++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    common_holiday_event = Event.find_all_by_is_common_and_is_holiday(true,true, :conditions => ["(start_date BETWEEN ? AND ?) or (end_date BETWEEN ? AND ?) or (? BETWEEN start_date AND end_date) or (? BETWEEN start_date AND end_date)",first_day,last_day,first_day,last_day,first_day,last_day])
    @common_holiday_event_array = []
    common_holiday_event.each do |h|
      if h.start_date.to_date == h.end_date.to_date
        @common_holiday_event_array.push h if h.start_date.to_date == @date
      else
        ( h.start_date.to_date..h.end_date.to_date).each do |d|
          @common_holiday_event_array.push h if d == @date
        end
      end
    end
    non_common_holiday_events = Event.find_all_by_is_common_and_is_holiday(false,true, :conditions => ["(start_date BETWEEN ? AND ?) or (end_date BETWEEN ? AND ?) or (? BETWEEN start_date AND end_date) or (? BETWEEN start_date AND end_date)",first_day,last_day,first_day,last_day,first_day,last_day],:include=>[:batch_events])
    @student_batch_not_common_holiday_event_array = []
    non_common_holiday_events.each do |h|
      if h.start_date.to_date == h.end_date.to_date
        if h.start_date.to_date == @date
          @student_batch_not_common_holiday_event_array.push(h) if h.batch_events.collect(&:batch_id).include?(self.id)
        end
      else
        (h.start_date.to_date..h.end_date.to_date).each do |d|
          if d == @date
            @student_batch_not_common_holiday_event_array.push(h) if h.batch_events.collect(&:batch_id).include?(self.id)
          end
        end
      end
    end
    @calender_events += @common_holiday_event_array.to_a + @student_batch_not_common_holiday_event_array.to_a
    #+++==================================================================================================================================
    return @calender_events
  end

  def fetch_timetable_summary(date)
    tt=self.time_table_class_timings.first(:include=>[:timetable,{:time_table_class_timing_sets=>{:class_timing_set=>:class_timings}}],
      :conditions=>["timetables.start_date <= ? and timetables.end_date >= ?",date,date])
    if tt.present?
      tt_id=tt.timetable_id
      entries=[]
      entries+=TimetableEntry.all(:select=>"timetable_entries.*,
              s.name as sname,s.id as suid,
              employees.id as eid,employees.first_name as ename,
              classrooms.name as cname,buildings.name as bname,ac.date as ddate",
        :conditions=>["timetable_entries.batch_id=? and timetable_id=? and weekday_id=? and s.elective_group_id IS NULL",
          self.id,tt_id,date.to_date.wday],
        :include=>[:class_timing,:employees,:timetable_swaps],
        :joins=>"INNER JOIN subjects s on s.id = timetable_entries.entry_id and timetable_entries.entry_type = 'Subject'
              LEFT OUTER JOIN teacher_timetable_entries ttes on ttes.timetable_entry_id=timetable_entries.id
              LEFT OUTER JOIN employees on ttes.employee_id=employees.id
              LEFT OUTER JOIN allocated_classrooms ac on ac.timetable_entry_id=timetable_entries.id
              LEFT OUTER JOIN classrooms on classrooms.id=ac.classroom_id
              LEFT OUTER JOIN buildings on buildings.id=classrooms.building_id")


      entries+=TimetableEntry.all(:select=>"timetable_entries.*,s.id as suid,s.name as sname,employees.id
              as eid,employees.first_name as ename,classrooms.name as cname,buildings.name as bname,ac.date as ddate",
        :conditions=>["timetable_entries.batch_id=? and timetable_id=? and weekday_id=?",self.id,tt_id,date.to_date.wday],
        :include=>[:class_timing,:employee,:timetable_swaps],
        :joins=>"LEFT OUTER JOIN elective_groups eg on eg.id=timetable_entries.entry_id and timetable_entries.entry_type = 'ElectiveGroup'
              INNER JOIN subjects s on s.elective_group_id=eg.id

              LEFT OUTER JOIN employees_subjects es on es.subject_id=s.id and es.school_id = #{self.school_id}
              INNER JOIN employees on employees.id = es.employee_id
              LEFT OUTER JOIN allocated_classrooms ac on ac.subject_id=s.id and ac.timetable_entry_id=timetable_entries.id
              LEFT OUTER JOIN classrooms on ac.classroom_id=classrooms.id LEFT OUTER JOIN buildings on buildings.id=classrooms.building_id")
      entries=entries.sort{|a,b| a.class_timing.start_time <=> b.class_timing.start_time}
      ct_hash = entries.group_by(&:class_timing_id)
      hash = ActiveSupport::OrderedHash.new { |h, k| h[k] = Hash.new(&h.default_proc) }

      ct_hash.each do |ctid,v|
        tcount=0
        class_timing = v.detect{|c| c.class_timing_id == ctid}
        hash[ctid][:class_timing] = "#{format_date(class_timing.class_timing.start_time,:format=>:time)} - #{format_date(class_timing.class_timing.end_time,:format=>:time)}"
        subjects = v.group_by(&:suid)

        subjects.each do |suid,v1|
          subject = v1.first
          sub_timetable_swaps = subject.timetable_swaps.select {|ts| ts.date == date }
          hash[ctid][:subjects][suid][:subject_name] = sub_timetable_swaps.present? ? sub_timetable_swaps.first.subject.name : subject.sname
          scount=0
          employees = v1.group_by(&:eid)
          employees = {employees.keys.first => employees.values.first} if sub_timetable_swaps.present?
          employees.each do |emid,v2|
            employee = v2.first
            hash[ctid][:subjects][suid][:employees][emid][:employee_name] = sub_timetable_swaps.present? ? (sub_timetable_swaps.first.employee.present? ? sub_timetable_swaps.first.employee.first_name : t('deleted_user')) : employee.ename
            date_specific=v2.collect{|r| [r.cname,r.bname] if (r.ddate.present? and r.ddate.to_date==date)}
            non_date_specific=v2.collect{|r| [r.cname,r.bname] unless (r.ddate.present?)}
            unless date_specific.compact.empty?
              hash[ctid][:subjects][suid][:employees][emid][:rooms]=date_specific.compact
              tcount+=date_specific.compact.count==0 ? 1 : date_specific.compact.count
              scount+=date_specific.compact.count==0 ? 1 : date_specific.compact.count
              hash[ctid][:subjects][suid][:employees][emid][:ecount]=date_specific.compact.count==0 ? 1 : date_specific.compact.count
            else
              hash[ctid][:subjects][suid][:employees][emid][:rooms]=non_date_specific.compact
              tcount+=non_date_specific.compact.count==0 ? 1 : non_date_specific.compact.count
              scount+=non_date_specific.compact.count==0 ? 1 : non_date_specific.compact.count
              hash[ctid][:subjects][suid][:employees][emid][:ecount]=non_date_specific.compact.count==0 ? 1 : non_date_specific.compact.count
            end
          end
          hash[ctid][:subjects][suid][:scount] = scount
        end
        hash[ctid][:tcount] = tcount
      end
      hash
    end
  end

  def subject_wise_normal_subjects(timetable_id)
    normal_subjects= []

    ttcts = TimeTableClassTiming.find_all_by_timetable_id_and_batch_id(timetable_id,self.id,
      :joins=>"INNER JOIN time_table_class_timing_sets ttcts on ttcts.time_table_class_timing_id = time_table_class_timings.id").map(&:time_table_class_timing_sets).flatten.group_by(&:weekday_id)

    ttcts.each_pair do |k,v|
      classtimings = v.map(&:class_timing_set).uniq.map(&:class_timings)
      normal_subjects += Subject.all(
        :select=>"subjects.*,employees.id as eid,employees.first_name as ename,employees.last_name, ttes.id as tid, ttes.class_timing_id",
        :conditions=>["subjects.is_deleted = ? and subjects.batch_id=? and subjects.elective_group_id IS NULL and ttes.weekday_id = ? and ttes.class_timing_id in (?)",false,self.id,k,classtimings.flatten.map(&:id)],
        :joins=>"INNER JOIN timetable_entries ttes on ttes.entry_id=subjects.id and ttes.entry_type = 'Subject' and ttes.timetable_id='#{timetable_id} and ttes.class_timing_id in (#{classtimings.flatten.map(&:id)} and ttes.weekday_id = #{k})'
              LEFT OUTER JOIN teacher_timetable_entries tttes on ttes.id = tttes.timetable_entry_id
              LEFT OUTER JOIN employees on employees.id=tttes.employee_id ")
    end
    sub_hash = normal_subjects.group_by{|s| s.id}
    hsh = Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
    sub_hash.each do |sub_id,v|
      record = normal_subjects.detect{|s| s.id == sub_id}
      hsh[sub_id][:subject_name] = record.name
      hsh[sub_id][:total_periods] =v.reject{|s| s.tid.nil?}.map{|x| x.tid}.uniq.count
      employees = v.group_by(&:eid)
      hsh[sub_id][:employee_count]=employees.count
      employees.each do |eid,v1|
        emp_record=v1.first
        hsh[sub_id][:employees][eid][:employee_name]=emp_record.ename
        hsh[sub_id][:employees][eid][:emp_periods]=v1.reject{|p| p.tid.nil?}.count
        hsh[sub_id][:employees][eid][:periods_present]=v1.reject{|p| p.tid.nil?}.count > 0 ? true : false
      end
    end
    hsh
  end

  def employee_wise_normal_subjects(timetable_id)
    normal_employees=Employee.all(:select=>"employees.*,ttes.employee_id as eid,employees.first_name as ename,tte.id,s.name as sname,s.id as sid",
      :joins=>"LEFT OUTER JOIN teacher_timetable_entries ttes on ttes.employee_id = employees.id
              RIGHT OUTER JOIN timetable_entries tte on tte.id=ttes.timetable_entry_id
              LEFT OUTER JOIN subjects s on s.id=tte.entry_id and tte.entry_type='Subject'",
      :conditions=>["tte.timetable_id=? and tte.batch_id=? and tte.entry_type = 'Subject'",timetable_id,self.id])
    emp_hash = normal_employees.group_by{|e| e.eid}
    hsh = Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
    emp_hash.each do |emp_id,v|
      record = normal_employees.detect{|e| e.eid == emp_id}
      hsh[emp_id][:emp_name] = record.ename
      hsh[emp_id][:total_periods]=v.count
      subjects=v.group_by(&:sid)
      hsh[emp_id][:subjects_count]=subjects.count
      subjects.each do |sid,v1|
        sub_record=v1.first
        hsh[emp_id][:subjects][sid][:subject_name]=sub_record.sname
        hsh[emp_id][:subjects][sid][:subject_count]=v1.count
      end
    end
    hsh
  end

  def employee_wise_electives_timetable_assignments (timetable_id)
    elective_subjects = self.subjects.scoped(
      :select=>'subjects.id,subjects.elective_group_id,subjects.name,eg.name as elective_group_name,tte.id as ttid,em.first_name,em.last_name,em.id as emid',
      :conditions=>["subjects.elective_group_id is not null and em.id is not null and tte.timetable_id = ?",timetable_id],
      :joins=>"INNER JOIN elective_groups eg ON eg.id = subjects.elective_group_id
              INNER JOIN timetable_entries tte ON tte.entry_id = subjects.elective_group_id and tte.entry_type = 'ElectiveGroup'
              LEFT OUTER JOIN teacher_timetable_entries ttes on ttes.timetable_entry_id=tte.id
              LEFT OUTER JOIN employees_subjects es on es.subject_id = subjects.id
              INNER JOIN employees em on em.id=es.employee_id ")
    elective_subjects.reject!{|eg| eg.ttid.nil?}
    em_hash = elective_subjects.group_by{|es| es.emid unless es.emid.nil?}
    hsh = Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
    em_hash.each do |emid,v|
      record = elective_subjects.detect{|es| es.emid == emid}
      hsh[emid][:employee_name] = record.first_name + ' ' + record.last_name
      v.reject!{|s| s.ttid.nil?}
      hsh[emid][:total] = v.reject{|s| s.ttid.nil?}.map{|x| x.ttid}.uniq.count
      electives = v.group_by(&:elective_group_id)
      electives.each do |egid,v1|
        elective = elective_subjects.detect{|es| es.elective_group_id == egid}
        hsh[emid][:elective_groups][egid][:group_name] = elective.elective_group_name
        hsh[emid][:elective_groups][egid][:subjects] = v1.collect(&:name).uniq
        hsh[emid][:elective_groups][egid][:count] = v1.collect(&:ttid).uniq.count
      end
    end
    hsh
  end

  #FIXME not specific to batch
  def roll_number_enabled?
    return Configuration.find_or_create_by_config_key('EnableRollNumber').config_value == "1" ? true : false
  end

  def fetch_first_cce_exam_category
    #first_exam_group=self.exam_groups.find(:all,:joins=>:exams,:conditions=>["exam_groups.cce_exam_category_id is not  NULL"],:order=>"exams.created_at asc")
    first_exam_group=self.exam_groups.find(:all,:conditions=>["exam_groups.cce_exam_category_id is not  NULL"])
    first_cce_category_id=first_exam_group.first.try(:cce_exam_category_id)
  end

  def fetch_gradebook_reports
    arr = []
    list = []
    grb = self.generated_report_batches.all(
      :joins => ['INNER JOIN generated_reports on generated_reports.id = generated_report_batches.generated_report_id LEFT JOIN assessment_terms on assessment_terms.id = generated_reports.report_id AND  generated_reports.report_type = "AssessmentTerm" LEFT JOIN assessment_groups on assessment_groups.id = generated_reports.report_id AND  generated_reports.report_type = "AssessmentGroup"'],
      :select => 'generated_report_batches.id as g_id , generated_reports.report_type as r_type, CONCAT_WS(" ", assessment_terms.name, assessment_groups.name ) AS name, CONCAT_WS(" ", assessment_groups.parent_id, assessment_terms.id) as parent_id',
      :order => 'name',
      :conditions=>["report_type in (?)",['AssessmentTerm','AssessmentGroup']]).group_by(&:parent_id)
    grb.each_pair{|key, value| (arr = [AssessmentTerm.find_by_id(key.to_i).name,value.map{|v| [v.name,v.g_id]}]; list.push(arr)) if key.present?}
    arr = []
    self.generated_report_batches.find(:all,
      :joins=>['INNER JOIN generated_reports on generated_reports.id = generated_report_batches.generated_report_id LEFT JOIN assessment_plans on assessment_plans.id = generated_reports.report_id AND  generated_reports.report_type = "AssessmentPlan"'],
      :select=>'generated_report_batches.id,generated_reports.report_type,assessment_plans.name',
      :order => 'name',
      :conditions=>["report_type = ?",'AssessmentPlan']).map{|plan| arr.push(plan.name,plan.id)}
    arr1 = arr2 = []
    arr1.push(arr)
    arr2 = ["Planner"]
    arr2.push(arr1)
    list.unshift(arr2) if arr.present?
    list
  end
  def effective_students_for_certificate(options={:active_check=>true})
    if self.is_active? && options[:active_check]==true
      return self.students.all(:order => Student.sort_order)
    else
      batch = Batch.find(self.id)
      active_student_ids = batch.students.collect(&:id)
      archived_student_ids = batch.archived_students.collect(&:id)
      possible_student_ids = BatchStudent.all(:conditions => {:batch_id =>self.id}).collect(&:student_id)

      result_hash = BatchStudent.all(:conditions => ["student_id in (?)",possible_student_ids],
        :order => "created_at ASC").group_by(&:student_id)
      arr = []
      result_hash.each do |key,val|
        arr << val.last
      end
      filtered_st_ids = arr.select {|f| f.batch_id == batch.id && (Student.find_by_id(f.student_id).present? && Student.find(f.student_id).batch.academic_year_id != Batch.find(f.batch_id).academic_year_id)}.collect(&:student_id)
      students = Student.find_all_by_id(active_student_ids + filtered_st_ids, :order => Student.sort_order) + ArchivedStudent.find_all_by_id(archived_student_ids, :order =>  ArchivedStudent.sort_order)
      return students
    end
  end

end
