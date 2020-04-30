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
class Course < ActiveRecord::Base
  extend FeeDefaultersSqlGenerator
  GRADINGTYPES = {"1"=>"GPA","2"=>"CWA","3"=>"CCE","4"=>"ICSE"}
  attr_accessor :course_batches
  validates_presence_of :course_name, :code
  validates_uniqueness_of :code,:scope=> [:is_deleted],:if=> 'is_deleted == false'
  validate :presence_of_initial_batch, :on => :create
  validate :presence_of_exam_groups, :on => :update
 
  validates_format_of :roll_number_prefix, :with => /^[A-Z0-9_-]*$/i
  validates_length_of :roll_number_prefix, :maximum => 6, :allow_blank => true
  has_many :batches
  has_many :batch_groups
  has_many :ranking_levels
  has_many :class_designations
  has_many :subject_amounts
  has_many :students ,:through=>:batches
  has_many :student_records,:through=>:batches
  has_many :record_batch_assignments,:through=>:batches
  accepts_nested_attributes_for :batches
  has_and_belongs_to_many :observation_groups
  has_many :eiop_settings
  has_many :record_assignments
  has_many :record_groups,:through=> :record_assignments,:order=>'record_assignments.priority asc'
  accepts_nested_attributes_for :record_assignments,:allow_destroy => true
  has_and_belongs_to_many_with_deferred_save :cce_weightages
  has_many :assessment_plans_courses
  has_many :assessment_plans, :through => :assessment_plans_courses
  has_many :assessment_groups, :as => :parent
  has_many :assessment_schedules
  has_many :assessment_group_batches
  has_many :subject_groups
  has_many :course_subjects, :as => :parent
  has_many :course_elective_groups, :as => :parent
  has_many :all_course_subjects,  :foreign_key => :course_id, :class_name => 'CourseSubject' , :order => 'priority asc'
  has_many :all_course_elective_groups,  :foreign_key => :course_id, :class_name => 'CourseElectiveGroup' , :order => 'priority asc'
  has_many :subject_imports
  has_one :course_transcript_setting
  accepts_nested_attributes_for :all_course_subjects,:allow_destroy => true
  #  attr_accessor :allocation_validation_errors, :allocation_status

  before_save :cce_weightage_valid

  named_scope :active, :conditions => { :is_deleted => false }, :order => 'course_name asc'
  named_scope :deleted, :conditions => { :is_deleted => true }, :order => 'course_name asc'
  # FIXME make distinct course output
  named_scope :has_batches, :conditions => { :is_deleted => false ,:batches=>{:is_deleted=>false}},:joins=>:batches,:select=>"DISTINCT(courses.id),courses.*"
  named_scope :has_active_batches, :conditions => { :is_deleted => false ,:batches=>{:is_deleted=>false,:is_active=>true}},:joins=>:batches,:select=>"DISTINCT(courses.id),courses.*"
  named_scope :has_inactive_batches, :conditions => { :is_deleted => false ,:batches=>{:is_deleted=>false,:is_active=>false}},:joins=>:batches,:select=>"DISTINCT(courses.id),courses.*"
  named_scope :cce, {:select => "courses.*",:conditions=>{:grading_type => GRADINGTYPES.invert["CCE"],:is_deleted => false}, :order => 'course_name asc'}
  named_scope :icse, {:select => "courses.*",:conditions=>{:grading_type => GRADINGTYPES.invert["ICSE"],:is_deleted => false}, :order => 'course_name asc'}

  #  def allocation_validation batches
  #    batches.each do |batch|
  #      batch.allocation_validation_errors = {}
  #      batch.allocation_validation_errors[:no_class_timing_set] = true unless batch.batch_class_timing_sets.present?
  #      batch.allocation_validation_errors[:no_class_timing] = true unless batch.batch_class_timing_sets.select { |y| y if y.class_timing_set.class_timings.present? }.present?
  #      batch.allocation_validation_errors[:no_subject] = true unless (batch.subjects.present? or batch.elective_groups.present?)
  #      batch.allocation_validation_errors[:no_employee] = true unless batch.subjects.select {|y| y unless y.employees.present? }.present?
  #    end

  #  end
  
  def subject_components
    components = []
    components += self.course_elective_groups
    components += self.subject_groups
    components += self.course_subjects
    
    components.sort_by {|child| [child.priority ? 0 : 1,child.priority || 0]}
  end
  
  def components_split_ordered
    components = []
    components += self.subject_groups
    components += self.all_course_subjects
    components += self.all_course_elective_groups
    
    components.sort_by {|child| [child.priority ? 0 : 1,child.priority || 0]}
  end
  
  def subject_components_for_priority
    components = []
    components += self.course_elective_groups
    components += self.subject_groups
    components += self.course_subjects
    components += self.all_course_subjects.select{|x| (x.parent_type == "SubjectGroup" || x.parent_type == "CourseElectiveGroup") and x.is_deleted == false}
    components.sort_by {|child| [child.priority ? 0 : 1,child.priority || 0]}
  end
  
  
  def build_all_course_subjects_with_batches(subject_id = nil)
    subjects = if subject_id.nil?
                all_course_subjects
               else
                CourseSubject.find_all_by_id(subject_id,:include=>{:subjects => [:batch, :exams, :timetable_entries, :subject_assessments, :subject_attribute_assessments]})
               end
    @course_batches = batches.active
    subjects.each do |sub|
      @course_batches.each do |batch| 
        sub.subjects.build(:batch => batch) unless sub.subjects.to_a.find{|s| (s.batch_id == batch.id) and !s.is_deleted }
      end
    end
    subjects
  end
  
  def imported_components(course_id)
    {
      :course_subjects => self.all_course_subjects.all(:conditions => {:import_from => course_id}).collect(&:previous_id).compact,
      :subject_groups  => self.subject_groups.all(:conditions => {:import_from => course_id}).collect(&:previous_id).compact,
      :course_elective_groups => self.all_course_elective_groups.all(:conditions => {:import_from => course_id}).collect(&:previous_id).compact
    }
  end
  
  def all_normal_course_subjects
    all_course_subjects.without_graded.select{|s| s.parent_type != 'CourseElectiveGroup' }
  end
  
  def all_elective_course_subjects
    all_course_subjects.without_graded.select{|s| s.parent_type == 'CourseElectiveGroup' }
  end
  
  def active_students
    batches.all(:joins=>:students,:conditions=>{:batches=>{:is_active=>true, :is_deleted=>false}},:select=>'students.*')
  end
  
  def active_students_in_academic_year(ayi)
    batches.all(:joins=>:students,:conditions=>{:batches=>{:is_active=>true, :is_deleted=>false, :academic_year_id => ayi}},:select=>'students.*')
  end
  
  def batches_in_academic_year(ayi)
    batches.with_academic_year(ayi)
  end
  
  def batches_in_academic_year_with_subject(ayi)
    batches.with_academic_year(ayi).all(:joins => :subjects, :group => 'batches.id')
  end
  
  def presence_of_exam_groups
    if grading_type == '3' and grading_type_changed?
      status = true
      self.batches.each do |batch|
        if batch.exam_groups.present?
          batch.exam_groups.each do |eg|
            status = false if eg.cce_exam_category_id.nil?
          end
        end
      end
      errors.add_to_base :cannot_change_grading_system unless status
    end
  end

  def presence_of_initial_batch
    errors.add_to_base :should_have_an_initial_batch if batches.length == 0
  end
  
  def active_assessment_groups(ay_id)
    batches.all(:joins=>{:assessment_group_batches => :assessment_group},
      :conditions => ['assessment_groups.academic_year_id = ?', ay_id],
      :select => 'DISTINCT assessment_groups.*')
  end
    
  def inactivate
    update_attribute(:is_deleted, true)
  end

  def activate
    update_attribute(:is_deleted, false)
  end

  def full_name
    "#{course_name} #{section_name}"
  end

  def active_batches
    self.batches.all(:conditions=>{:is_active=>true,:is_deleted=>false})
  end

  def is_tutor_and_has_batch_in_this_course
    current_user=Authorization.current_user
    employee = current_user.employee_entry
    if employee.is_a_batch_tutor?
      user_ids = []
      Course.find(self.id).batches.each do |batch|
        user_ids += batch.employees.collect{|e| e.user.id}
      end
      return user_ids.include?(current_user.id)
    else
      return false
    end
  end
  
  def is_tutor_and_has_batch_in_this_course_academic_year(ay)
    current_user=Authorization.current_user
    employee = current_user.employee_entry
    if employee.is_a_batch_tutor?
      user_ids = []
      Course.find(self.id).batches.with_academic_year(ay).each do |batch|
        user_ids += batch.employees.collect{|e| e.user.id}
      end
      return user_ids.include?(current_user.id)
    else
      return false
    end
  end
  
  def is_subject_teacher_and_has_batch_in_this_course
    current_user=Authorization.current_user
    employee = current_user.employee_entry
    if employee.subjects.present?
      user_ids = []
      Course.find(self.id).batches.each do |batch|
        user_ids += batch.employees_subjects.collect{|e| Employee.find(e.employee_id).user.id}
      end
      return user_ids.include?(current_user.id)
    else
      return false
    end
  end

  def has_batch_groups_with_active_batches
    batch_groups = self.batch_groups
    if batch_groups.empty?
      return false
    else
      batch_groups.each do|b|
        return true if b.has_active_batches==true
      end
    end
    return false
  end

  def roll_number_enabled?
    @enabled ||= Configuration.get_config_value("EnableRollNumber") == "1" ? true : false
  end

  def find_course_rank(batch_ids,sort_order)
    batches = Batch.find_all_by_id(batch_ids)
    @students = Student.find_all_by_batch_id(batches, :order =>"#{Student.sort_order}")
    @grouped_exams = GroupedExam.find_all_by_batch_id(batches)
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
      m = 0
      student_scores.each do|student_score|
        if student_score[0]==student.id
          m = student_score[1]
        end
      end
      if sort_order=="" or sort_order=="rank-ascend" or sort_order=="rank-descend"
        ranked_students << [(ordered_scores.index(m) + 1),m,student.id,student]
      else
        ranked_students << [student.full_name,(ordered_scores.index(m) + 1),m,student.id,student]
      end
    end
    if sort_order=="" or sort_order=="rank-ascend" or sort_order=="name-ascend"
      ranked_students = ranked_students.sort
    else
      ranked_students = ranked_students.sort.reverse
    end
  end

  def cce_enabled?
    Configuration.cce_enabled? and grading_type == "3"
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

  def icse_enabled?
    Configuration.icse_enabled? and grading_type == "4"
  end
  #  def guardian_email_list
  #    email_addresses = []
  #    students = self.students
  #    students.each do |s|
  #      email_addresses << s.immediate_contact.email unless s.immediate_contact.nil?
  #    end
  #    email_addresses
  #  end
  #
  #  def student_email_list
  #    email_addresses = []
  #    students = self.students
  #    students.each do |s|
  #      email_addresses << s.email unless s.email.nil?
  #    end
  #    email_addresses
  #  end
  class << self
    def grading_types
      hsh =  ActiveSupport::OrderedHash.new
      hsh["0"]=t('normal')
      types = Configuration.get_grading_types
      types.each{|t| hsh[t] = GRADINGTYPES[t]}
      hsh
    end
    def grading_types_as_options
      grading_types.invert.sort_by{|k,v| v}
    end
  end

  def cce_weightages_for_exam_category(cce_exam_cateogry_id)
    cce_weightages.all(:conditions=>{:cce_exam_category_id=>cce_exam_cateogry_id})
  end

  def self.course_details(parameters)
    sort_order=parameters[:sort_order]
    unless sort_order.nil?
      courses=Course.all(:select=>"courses.id,courses.course_name,courses.code,courses.section_name,count(students.id) as student_count,count(IF(students.gender like '%m%',1,NULL)) as male_count,count(IF(students.gender like '%f%',1,NULL)) as female_count,count(DISTINCT IF(batches.is_deleted=0 and batches.is_active=1,batches.id,NULL)) as batch_count",:conditions=>{:courses=>{:is_deleted=>false}},:joins=>"left outer join batches on courses.id=batches.course_id left outer join students on batches.id=students.batch_id",:group=>"courses.id",:order=>sort_order)
    else
      courses=Course.all(:select=>"courses.id,courses.course_name,courses.code,courses.section_name,count(students.id) as student_count,count(IF(students.gender like '%m%',1,NULL)) as male_count,count(IF(students.gender like '%f%',1,NULL)) as female_count,count(DISTINCT IF(batches.is_deleted=0 and batches.is_active=1,batches.id,NULL)) as batch_count",:conditions=>{:courses=>{:is_deleted=>false}},:joins=>"left outer join batches on courses.id=batches.course_id left outer join students on batches.id=students.batch_id",:group=>"courses.id",:order=>'course_name ASC')
    end
    data=[]
    col_heads=["#{t('no_text')}","#{t('name')}","#{t('code')}","#{t('section')}","#{t('batch')}","#{t('students')}","#{t('male')}","#{t('female')}"]
    data << col_heads
    courses.each_with_index do |c,i|
      col=[]
      col<< "#{i+1}"
      col<< "#{c.course_name}"
      col<< "#{c.code}"
      col<< "#{c.section_name}"
      col<< "#{c.batch_count}"
      col<< "#{c.student_count}"
      col<< "#{c.male_count}"
      col<< "#{c.female_count}"
      col=col.flatten
      data << col
    end
    return data
  end

  def self.course_fee_defaulters(parameters)
    sort_order=parameters[:sort_order]||nil
    courses=Course.all(:select=>"courses.id,courses.course_name,courses.code,courses.section_name,sum(balance) balance,count(DISTINCT IF(batches.is_deleted='0',batches.id,NULL)) as batch_count",:joins=>"INNER JOIN batches on batches.course_id=courses.id INNER JOIN #{derived_sql_table} finance on finance.batch_id=batches.id",:group=>'courses.id',:order=>sort_order)
    data=[]
    col_heads=["#{t('no_text')}","#{t('name')}","#{t('code')}","#{t('section')}","#{t('batches_text')}","#{t('balance')}(#{Configuration.currency})"]
    data << col_heads
    total_amount=0
    courses.each_with_index do |c,i|
      col=[]
      col<< "#{i+1}"
      col<< "#{c.course_name}"
      col<< "#{c.code}"
      col<< "#{c.section_name}"
      col<< "#{c.batch_count}"
      balance="#{c.balance.nil?? 0.0 : c.balance}".to_i
      total_amount+=balance
      col << balance
      col=col.flatten
      data<< col
    end
    data << ["#{t('total_amount')}","","","","",total_amount]
    return data
  end

  private

  def cce_weightage_valid
    cce_weightages.group_by(&:criteria_type).values.each do |v|
      unless v.collect(&:cce_exam_category_id).length == v.collect(&:cce_exam_category_id).uniq.length
        errors.add(:cce_weightages,"can't assign more than one FA or SA under a single exam category.")
        return false
      end
    end
    true

  end

end
