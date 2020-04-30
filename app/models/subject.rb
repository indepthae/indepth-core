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

class Subject < ActiveRecord::Base
  attr_accessor :selected
  belongs_to :batch
  belongs_to :elective_group
  belongs_to :subject_skill_set
  belongs_to :course_subject
  belongs_to :batch_subject_group
  has_many :timetable_entries,:foreign_key=>'subject_id'
  has_many :employees_subjects
  has_many :employees ,:through => :employees_subjects
  has_many :students_subjects
  has_many :students, :through => :students_subjects
  has_many :grouped_exam_reports
  has_many :timetable_swaps
  has_many :subject_leaves
  has_many :exams
  has_many :cce_reports
  has_many :allocated_classrooms

  has_many :timetable_entries, :as => :entry
  has_many :subject_assessments
  has_many :attribute_assessments
  has_many :converted_assessment_marks, :as => :markable
  has_many :subject_attribute_assessments
  has_many :gradebook_remarks, :as => :remarkable, :dependent=>:destroy
  has_many :marked_attendance_records
  
  has_and_belongs_to_many_with_deferred_save :fa_groups
  has_and_belongs_to_many_with_deferred_save :icse_weightages
  has_and_belongs_to_many_with_deferred_save :ia_groups
  validates_presence_of :name, :max_weekly_classes, :code,:batch_id
  validates_presence_of :credit_hours, :if=>:check_grade_type
  validates_numericality_of :max_weekly_classes, :allow_nil => false, :greater_than_or_equal_to => 1
  validates_numericality_of :amount,:allow_nil => true
  validates_uniqueness_of :code, :case_sensitive => false, :scope=>[:batch_id,:is_deleted] ,:if=> 'is_deleted == false'
  validates_uniqueness_of :course_subject_id, :scope=>[:batch_id,:is_deleted] ,:if=> Proc.new{|s| !s.is_deleted and s.course_subject_id.present? }
  validates_uniqueness_of :is_asl, :scope=>[:batch_id,:is_deleted] ,:if=> 'is_deleted == false and is_asl == true' , :message => "has already been assigned for this batch"
  validates_uniqueness_of :is_sixth_subject, :scope=>[:batch_id,:is_deleted] ,:if=> 'is_deleted == false and is_sixth_subject == true' , :message => "has already been assigned for this batch"
  named_scope :for_batch, lambda { |b| { :conditions => { :batch_id => b.to_i, :is_deleted => false } } }
  named_scope :without_exams, :conditions => { :no_exams => false, :is_deleted => false }
  named_scope :active, :conditions => { :is_deleted => false }
  named_scope :active_and_has_exam, :conditions => { :is_deleted => false ,:no_exams=>false },:joins=>:exams
  named_scope :normal_subject, :conditions => { :elective_group_id => nil }
  named_scope :active_batch_subjects, { :joins=>:batch, :include=>:batch, :conditions =>{:batches=>{:is_active=>true,:is_deleted=>false}}}
  named_scope :asl_subject,:conditions=>{:is_deleted => false,:is_asl=>true}
  named_scope :ordered,:order => 'priority, created_at'
  before_save :fa_group_valid
  before_save :icse_weightage_valid
  before_save :icse_fa_group_valid
  before_save :check_elective_group
  after_save  :update_timetable_summary_status
  after_destroy :update_timetable_summary_status
  after_destroy :deactivate_elective_and_subject_group
  before_destroy :check_dependency
  before_save :skip_asl_data
  after_create :import_fa_groups
  before_create :check_batch_status
  before_save :import_groups, :if => Proc.new{|s| s.course_subject_id_changed?}
  after_update :deactivate_elective_and_subject_group, :if => Proc.new{|s| s.is_deleted == true }

  delegate :name, :to => :batch_subject_group,:prefix => true, :allow_nil => true

  def import_fa_groups
    if self.batch.course.cce_enabled?
      previous_batch=Batch.find(:first,
        :order=>'id desc',
        :include => [:subjects, { :elective_groups => :subjects }],
        :conditions=>"batches.id < '#{self.batch_id}' AND batches.is_deleted = 0 AND course_id = ' #{self.batch.course_id}'",
        :joins=>"INNER JOIN subjects ON subjects.batch_id = batches.id  AND subjects.is_deleted = 0")
      if previous_batch.present?
        previous_subject = previous_batch.subjects.find_by_code(self.code)
        if previous_subject.present?
          self.fa_groups = previous_subject.fa_groups
          self.save
        end
      end
    end
  end

  def check_dependency
    no_dependency_for_deletion?
  end

  def parent_name_and_type(subject = nil)
    if batch_subject_group_id.present?
      [batch_subject_group.name, 'BatchSubjectGroup', batch_subject_group_id]
    else
      [batch.name, 'Batch', batch_id]
    end
  end

  def check_dependency
    no_dependency_for_deletion?
  end

  def name_with_code
    "#{name}&#x200E;(#{code})&#x200E;"
  end

  def fetch_skills
    skills = []
    if subject_skill_set_id.present?
      subject_skill_set.subject_skills.each do |skill|
        skills << skill
        skills +=  skill.sub_skills
      end
    end
    skills.flatten
  end

  def subject_group_name
    self.course_subject.try(:subject_group).try(:name)
  end

  def link_to_course_subject(course_subject_id)
    c_subject = CourseSubject.find course_subject_id
    self.attributes = {:course_subject_id => c_subject.id, :priority => c_subject.priority, :subject_skill_set_id => c_subject.subject_skill_set_id }
    self.save

    self
  end

  def import_groups
    if self.course_subject_id.present?
      c_subject = CourseSubject.find self.course_subject_id
      if c_subject.parent_type == 'CourseElectiveGroup'
        course_e_group = c_subject.parent
        if self.elective_group_id.present?
          e_group = self.elective_group
          e_group.course_elective_group_id = course_e_group.id
          e_group.save
        else
          e_group = course_e_group.find_or_create_e_group(self.batch_id)
          self.elective_group_id = e_group.id
        end
        check_for_subject_group(course_e_group)
      end
      check_for_subject_group(c_subject)
    end
  end

  def check_for_subject_group(obj)
    if obj.parent_type == 'SubjectGroup'
      subject_group = obj.parent
      batch_group = subject_group.find_or_create_batch_groups(self.batch_id)
      self.batch_subject_group_id = batch_group.id
    end
  end

  def no_dependency_for_deletion?
    self.exams.blank? and self.timetable_entries.blank? and self.has_no_assessments and self.employees.blank? and self.students.blank?
  end

  def dependency_present?
    self.exams.present? or self.timetable_entries.present? or !self.has_no_assessments
  end

  def update_timetable_summary_status
    if (self.changed.include? "max_weekly_classes" or self.created_at == self.updated_at or self.destroyed?)
      Timetable.mark_summary_status({:model => self})
    end
  end
  
  def deactivate_elective_and_subject_group
    elective_group.inactivate if elective_group.present?
    batch_subject_group.check_and_destroy if batch_subject_group.present?
  end

  def is_tutor_in_this_batch
    current_user=Authorization.current_user
    employee = current_user.employee_entry
    if employee.is_a_batch_tutor?
      user_ids = self.batch.employees.collect{|e| e.user.id}
      return user_ids.include?(current_user.id)
    else
      return false
    end
  end

  def is_subject_teacher_for_this_subject
    current_user=Authorization.current_user
    employee = current_user.employee_entry
    if employee.subjects.present?
      user_ids = self.employees.collect{|e| e.user.id}
      return user_ids.include?(current_user.id)
    else
      return false
    end
  end

  def self.get_hash_priority
    hash = {:assigned_employees=>[:employee_number]}
    return hash
  end

  def check_batch_status
    Batch.exists?(:id=>self.batch_id, :is_deleted=>false, :is_active=>true)
  end

  def validate
    errors.add :is_sixth_subject, "has already been assigned for this batch" if ElectiveGroup.exists?(:is_sixth_subject => true,:batch_id=>self.batch_id,:is_deleted=>false) and self.is_sixth_subject == true
  end

  def skip_asl_data
    self.asl_mark = 20 if self.is_asl == false
  end

  def check_elective_group
    if self.elective_group_id.present?
      unless ElectiveGroup.find_by_id(self.elective_group_id,:conditions=>["is_deleted=?",false]).present?
        errors.add_to_base(:elective_group_not_active)
        return false
      else
        return true
      end
    else
      return true
    end
  end

  def check_grade_type
    unless self.batch.nil?
      batch = self.batch
      batch.gpa_enabled? or batch.cwa_enabled?
    else
      return false
    end
  end

  def inactivate
    update_attributes(:is_deleted=>true)
    self.employees_subjects.destroy_all
  end

  def lower_day_grade
    subjects = Subject.find_all_by_elective_group_id(self.elective_group_id) unless self.elective_group_id.nil?
    selected_employee = nil
    subjects.each do |subject|
      employees = subject.employees
      employees.each do |employee|
        if selected_employee.nil?
          selected_employee = employee
        else
          selected_employee = employee if employee.max_hours_per_day.to_i < selected_employee.max_hours_per_day.to_i
        end
      end
    end
    return selected_employee
  end

  def lower_week_grade
    subjects = Subject.find_all_by_elective_group_id(self.elective_group_id) unless self.elective_group_id.nil?
    selected_employee = nil
    subjects.each do |subject|
      employees = subject.employees
      employees.each do |employee|
        if selected_employee.nil?
          selected_employee = employee
        else
          selected_employee = employee if employee.max_hours_per_week.to_i  < selected_employee.max_hours_per_week.to_i
        end
      end
    end
    return selected_employee
  end

  def no_exam_for_batch(batch_id)
    grouped_exams = GroupedExam.find_all_by_batch_id(batch_id).collect(&:exam_group_id)
    return exam_not_created(grouped_exams)
  end

  def exam_not_created(exam_group_ids)
    exams = Exam.find_all_by_exam_group_id_and_subject_id(exam_group_ids,self.id)
    if exams.empty?
      return true
    else
      return false
    end
  end

  def full_name
    "#{batch.name}-#{code}"
  end

  def has_employee_privilege
    Authorization.current_user.has_subject_privilege(id)
  end


  def check_subject_show_in_course_exam(batch_ids)
    code=self.code
    subjects=Subject.find_all_by_batch_id_and_code(batch_ids,code)
    is_assigned = StudentsSubject.find_by_subject_id(subjects.collect(&:id))
    if is_assigned.nil?
      return false
    else
      return true
    end
  end

  def name_with_elective_group
    "#{name}" + (elective_group_id.nil? ? '' : " &#x200E;(#{t('elective')} : #{elective_group.name})&#x200E;")
  end

  def self.subject_details(parameters)
    sort_order=parameters[:sort_order]
    subject_search=parameters[:subject_search]
    course_id=parameters[:course_id]
    if subject_search.nil?
      if sort_order.nil?
        subjects=Subject.all(:select=>"batches.name as batch_name,batch_id,subjects.id,subjects.name,subjects.code,no_exams,max_weekly_classes,elective_group_id,courses.code as c_code",:joins=>[:batch=>:course],:conditions=>{:is_deleted=>false,:batches=>{:is_deleted=>false,:is_active=>true}},:order=>'name ASC')
      else
        subjects=Subject.all(:select=>"batches.name as batch_name,batch_id,subjects.id,subjects.name,subjects.code,no_exams,max_weekly_classes,elective_group_id,courses.code as c_code",:joins=>[:batch=>:course],:conditions=>{:is_deleted=>false,:batches=>{:is_deleted=>false,:is_active=>true}},:order=>sort_order)
      end
    else
      if sort_order.nil?
        if subject_search[:elective_subject]=="1" and subject_search[:normal_subject]=="0"
          unless subject_search[:batch_ids].nil? and course_id[:course_id] == ""
            subjects=Subject.all(:select=>"batches.name as batch_name,subjects.batch_id,subjects.id,subjects.name,subjects.code,no_exams,max_weekly_classes,elective_group_id,count(IF(students.batch_id=batches.id,students.id,NULL)) as student_count,courses.code as c_code",:joins=>"INNER JOIN `batches` ON `batches`.id = `subjects`.batch_id LEFT OUTER JOIN `students_subjects` ON students_subjects.subject_id = subjects.id LEFT OUTER JOIN `students` ON `students`.id = `students_subjects`.student_id INNER JOIN `courses` ON `courses`.id = `batches`.course_id",:group=>'subjects.id',:conditions=>["batches.id IN (?) and elective_group_id != ? and subjects.is_deleted=?",subject_search[:batch_ids],"",false],:order=>'name ASC')
          else
            subjects=Subject.all(:select=>"batches.name as batch_name,subjects.batch_id,subjects.id,subjects.name,subjects.code,no_exams,max_weekly_classes,elective_group_id,count(IF(students.batch_id=batches.id,students.id,NULL)) as student_count,courses.code as c_code",:joins=>"INNER JOIN `batches` ON `batches`.id = `subjects`.batch_id LEFT OUTER JOIN `students_subjects` ON students_subjects.subject_id = subjects.id LEFT OUTER JOIN `students` ON `students`.id = `students_subjects`.student_id INNER JOIN `courses` ON `courses`.id = `batches`.course_id",:group=>'subjects.id',:conditions=>["elective_group_id != ? and subjects.is_deleted=? and batches.is_deleted=? and batches.is_active=?","",false,false,true],:order=>'name ASC')
          end
        elsif subject_search[:elective_subject]=="0" and subject_search[:normal_subject]=="1"
          unless subject_search[:batch_ids].nil? and course_id[:course_id] == ""
            subjects=Subject.all(:select=>"batches.name as batch_name,batch_id,subjects.id,subjects.name,subjects.code,no_exams,max_weekly_classes,elective_group_id,courses.code as c_code",:joins=>[:batch=>:course],:conditions=>{:is_deleted=>false,:batches=>{:id=>subject_search[:batch_ids]},:elective_group_id=>nil},:order=>'name ASC')
          else
            subjects=Subject.all(:select=>"batches.name as batch_name,batch_id,subjects.id,subjects.name,subjects.code,no_exams,max_weekly_classes,elective_group_id,courses.code as c_code",:joins=>[:batch=>:course],:conditions=>{:is_deleted=>false,:elective_group_id=>nil,:batches=>{:is_deleted=>false,:is_active=>true}},:order=>'name ASC')
          end
        else
          unless subject_search[:batch_ids].nil? and course_id[:course_id] == ""
            subjects=Subject.all(:select=>"batches.name as batch_name,batch_id,subjects.id,subjects.name,subjects.code,no_exams,max_weekly_classes,elective_group_id,courses.code as c_code",:joins=>[:batch=>:course],:conditions=>{:is_deleted=>false,:batches=>{:id=>subject_search[:batch_ids]}},:order=>'name ASC')
          else
            subjects=Subject.all(:select=>"batches.name as batch_name,batch_id,subjects.id,subjects.name,subjects.code,no_exams,max_weekly_classes,elective_group_id,courses.code as c_code",:joins=>[:batch=>:course],:conditions=>{:is_deleted=>false,:batches=>{:is_deleted=>false,:is_active=>true}},:order=>'name ASC')
          end
        end
      else
        if subject_search[:elective_subject]=="1" and subject_search[:normal_subject]=="0"
          unless subject_search[:batch_ids].nil? and course_id[:course_id] == ""
            subjects=Subject.all(:select=>"batches.name as batch_name,subjects.batch_id,subjects.id,subjects.name,subjects.code,no_exams,max_weekly_classes,elective_group_id,count(IF(students.batch_id=batches.id,students.id,NULL)) as student_count,courses.code as c_code",:joins=>"INNER JOIN `batches` ON `batches`.id = `subjects`.batch_id LEFT OUTER JOIN `students_subjects` ON students_subjects.subject_id = subjects.id LEFT OUTER JOIN `students` ON `students`.id = `students_subjects`.student_id INNER JOIN `courses` ON `courses`.id = `batches`.course_id",:group=>'subjects.id',:conditions=>["batches.id IN (?) and elective_group_id != ? and subjects.is_deleted=?",subject_search[:batch_ids],"",false],:order=>sort_order)
          else
            subjects=Subject.all(:select=>"batches.name as batch_name,subjects.batch_id,subjects.id,subjects.name,subjects.code,no_exams,max_weekly_classes,elective_group_id,count(IF(students.batch_id=batches.id,students.id,NULL)) as student_count,courses.code as c_code",:joins=>"INNER JOIN `batches` ON `batches`.id = `subjects`.batch_id LEFT OUTER JOIN `students_subjects` ON students_subjects.subject_id = subjects.id LEFT OUTER JOIN `students` ON `students`.id = `students_subjects`.student_id INNER JOIN `courses` ON `courses`.id = `batches`.course_id",:group=>'subjects.id',:conditions=>["elective_group_id != ? and subjects.is_deleted=? and batches.is_deleted=? and batches.is_active=?","",false,false,true],:order=>sort_order)
          end
        elsif subject_search[:elective_subject]=="0" and subject_search[:normal_subject]=="1"
          unless subject_search[:batch_ids].nil? and course_id[:course_id] == ""
            subjects=Subject.all(:select=>"batches.name as batch_name,batch_id,subjects.id,subjects.name,subjects.code,no_exams,max_weekly_classes,elective_group_id,courses.code as c_code",:joins=>[:batch=>:course],:conditions=>{:is_deleted=>false,:batches=>{:id=>subject_search[:batch_ids]},:elective_group_id=>nil},:order=>sort_order)
          else
            subjects=Subject.all(:select=>"batches.name as batch_name,batch_id,subjects.id,subjects.name,subjects.code,no_exams,max_weekly_classes,elective_group_id,courses.code as c_code",:joins=>[:batch=>:course],:conditions=>{:is_deleted=>false,:elective_group_id=>nil,:batches=>{:is_deleted=>false,:is_active=>true}},:order=>sort_order)
          end
        else
          unless subject_search[:batch_ids].nil? and course_id[:course_id] == ""
            subjects=Subject.all(:select=>"batches.name as batch_name,batch_id,subjects.id,subjects.name,subjects.code,no_exams,max_weekly_classes,elective_group_id,courses.code as c_code",:joins=>[:batch=>:course],:conditions=>{:is_deleted=>false,:batches=>{:id=>subject_search[:batch_ids]}},:order=>sort_order)
          else
            subjects=Subject.all(:select=>"batches.name as batch_name,batch_id,subjects.id,subjects.name,subjects.code,no_exams,max_weekly_classes,elective_group_id,courses.code as c_code",:joins=>[:batch=>:course],:conditions=>{:is_deleted=>false,:batches=>{:is_deleted=>false,:is_active=>true}},:order=>sort_order)
          end
        end
      end
    end
    data=[]
    if subject_search !=nil and subject_search[:elective_subject]=="1" and subject_search[:normal_subject]=="0"
      col_heads=["#{t('no_text')}","#{t('name')}","#{t('code') }","#{t('max_weekly_classes') }","#{t('batch_name')}","#{t('students')}","#{t('exams_text')}"]
    else
      col_heads=["#{t('no_text')}","#{t('name')}","#{t('code') }","#{t('max_weekly_classes') }","#{t('batch_name')}","#{t('elective_subject')}","#{t('exams_text')}"]
    end
    data << col_heads
    subjects.each_with_index do |s,i|
      col=[]
      col<< "#{i+1}"
      col<< "#{s.name}"
      col<< "#{s.code}"
      col<< "#{s.max_weekly_classes}"
      col<< "#{s.c_code}-#{s.batch_name}"
      if subject_search !=nil and subject_search[:elective_subject]=="1" and subject_search[:normal_subject]=="0"
        col<< "#{s.student_count}"
      else
        col<< "#{ s.elective_group_id==nil ? t('no_texts') : t('yes_text')}"
      end
      col<< "#{s.no_exams==true ? t('no_texts') : t('yes_text')}"
      col=col.flatten
      data<< col
    end
    return data
  end

  def is_not_eligible_for_delete

    return true if Exam.find_by_subject_id(self.id).present?
    return true if TimetableEntry.find_by_entry_id_and_entry_type(self.id,'Subject').present?
    return true if (self.elective_group_id.present? and TimetableEntry.find_by_entry_id_and_entry_type(self.elective_group_id,'ElectiveGroup').present?)
    return true if self.students.present?
    return true unless has_no_assessments
    return true if self.employees.present?
    return false

  end

  def can_remove_employee_subject_association emp_id
    return (elective_group_id.present? ? elective_group : self).timetable_entries.all(:joins => "LEFT OUTER JOIN teacher_timetable_entries ttes on ttes.employee_id = #{emp_id} and ttes.timetable_entry_id = timetable_entries.id").count
  end

  def self.exam_enabled_batches
    Subject.find(:all,:conditions=>"no_exams=false")
  end

  def fetch_students
    if elective_group_id?
      students
    else
      batch.students
    end
  end

  def fetch_gradebook_students
    if elective_group_id?
      s_ids = students_subjects.collect(&:student_id)
      if batch.is_active?
        Student.find_all_by_id(s_ids, :order => Student.sort_order,:conditions=>{ :batch_id => @batch.id})
      else
        #        Student.find_all_by_id(s_ids, :order => Student.sort_order,:conditions=>{ :batch_id => @batch.id}) + ArchivedStudent.find_all_by_former_id(s_ids)
        Student.all(:joins=>[:batch_students,:students_subjects],:conditions=>["students_subjects.subject_id=? and students_subjects.batch_id=?",self.id,batch_id],
          :order=>"#{Student.sort_order}",:group=>"students.id") +
          ArchivedStudent.all(:joins => :students_subjects, :conditions => {:students_subjects => {:subject_id =>self.id, :batch_id => batch_id}}, :order => ArchivedStudent.sort_order)
      end
    else
      batch.effective_students
    end
  end

  def fetch_past_students(batch_id)
    if elective_group_id?
      Student.all(:joins=>[:batch_students,:students_subjects],:conditions=>["students_subjects.subject_id=? and students_subjects.batch_id=?",self.id,batch_id],
        :order=>"#{Student.sort_order}",:group=>"students.id") +
        ArchivedStudent.all(:joins => :students_subjects, :conditions => {:students_subjects => {:subject_id =>self.id, :batch_id => batch_id}})
    else
      student_ids = BatchStudent.all(:conditions => {:batch_id => batch_id}).collect(&:student_id)
      Student.all(:joins => :batch_students, :conditions=>{:batch_students =>{:batch_id => batch_id} }, :order => "#{Student.sort_order}") +
        ArchivedStudent.all(:conditions => {:former_id => student_ids})
    end
  end

  def has_no_assessments
    subject_assessments.blank? and subject_attribute_assessments.blank?
  end

  private

  def fa_group_valid
    fa_groups.group_by(&:cce_exam_category_id).values.each do |fg|
      if fg.length > 2
        errors.add(:base, "FA group cannot have more than 2 FA Group under a single exam category")
        return false
      end
    end
  end

  def icse_weightage_valid
    self.icse_weightages.group_by(&:icse_exam_category).values.each do |iw|
      if iw.length > 1
        errors.add(:base,"ICSE Weightage cannot have more than 1 weightage under a single Exam category")
        return false
      end
    end
  end

  def icse_fa_group_valid
    self.ia_groups.group_by(&:icse_exam_category).values.each do |ia|
      if ia.length > 1
        errors.add(:base, "Cannot assign more than one IA Group under a single Exam category")
        return false
      end
    end
  end

end
