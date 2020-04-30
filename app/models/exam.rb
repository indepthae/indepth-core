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

class Exam < ActiveRecord::Base
  validates_presence_of :start_time, :end_time
  validates_presence_of :maximum_marks, :minimum_marks, :if => :validation_should_present?
  validates_numericality_of :maximum_marks, :minimum_marks, :if => :validation_should_present?
  belongs_to :exam_group
  belongs_to :subject, :conditions => { :is_deleted => false }
  before_destroy :removable?
  before_save :update_exam_group_date
  validates_uniqueness_of :subject_id ,:scope => [:exam_group_id ], :message => "is already allocated for this exam group"
  has_one :event ,:as=>:origin,:dependent=>:destroy
  has_many :exam_scores
  has_many :asl_scores
  has_many :archived_exam_scores
  has_many :previous_exam_scores
  has_many :assessment_scores
  has_many :ia_scores
  #  has_and_belongs_to_many :cce_reports

  accepts_nested_attributes_for :exam_scores
  attr_accessor :subject_code
  attr_accessor :subject_name
 # after_save :verify_update_and_send_sms

  include CsvExportMod

  def validation_should_present?
    if self.exam_group.exam_type=="Grades"
      return false
    else
      return true
    end
  end

  def removable?
    return false if self.exam_scores.all(:conditions=>["exam_scores.marks IS NOT NULL OR exam_scores.grading_level_id IS NOT NULL"]).present?
    return false if self.ia_scores.all(:conditions=>["ia_scores.mark IS NOT NULL"]).present?
    return false if self.asl_scores.present?
    return true
  end

  def validate
    errors.add_to_base :minmarks_cant_be_more_than_maxmarks \
      if minimum_marks and maximum_marks and minimum_marks > maximum_marks
    unless self.start_time.nil? or self.end_time.nil?
      errors.add_to_base :end_time_cannot_before_start_time if self.end_time < self.start_time
    end

  end

  def before_save
    self.weightage = 0 if self.weightage.nil?
    #update_exam_group_date
  end

  def after_create
    create_exam_event
  end

  def after_update
    update_exam_event
  end

  def score_for(student_id)
    exam_score = self.exam_scores.find(:first, :conditions => { :student_id => student_id })
    exam_score.nil? ? ExamScore.new : exam_score
  end

  def asl_score_for(student_id)
    asl_score = self.asl_scores.find(:first, :conditions => { :student_id => student_id })
    asl_score.nil? ? AslScore.new : asl_score
  end

  def class_average_marks
    results = ExamScore.find_all_by_exam_id(self)
    scores = results.collect { |x| (x.marks/x.exam.maximum_marks)*100 unless x.marks.nil? or x.exam.maximum_marks.nil? or x.exam.maximum_marks==0}
    scores.delete(nil)
    return (scores.sum / scores.size) unless scores.size == 0
    return 0
  end

  def fa_groups
    subject.fa_groups.all(:order=>'id asc').select{|fg| fg.cce_exam_category_id == exam_group.cce_exam_category_id}
  end

  def is_subject_teacher_and_teaches_this_subject
    current_user=Authorization.current_user
    employee = current_user.employee_entry
    if employee.subjects.present?
      user_ids = self.subject.employees.collect{|e| e.user.id}
      return user_ids.include?(current_user.id)
    else
      return false
    end
  end
  
  def self.verify_update_and_send_sms(params)
    exam_group = ExamGroup.find(params[:id])
    AutomatedMessageInitiator.exam_schedule_published(exam_group) if params[:status] == "schedule"
    AutomatedMessageInitiator.exam_result_published(exam_group) if params[:status] == "result"
  end
  
  class<< self
    def check_roll_number_settings
      roll_number_enable =  Configuration.get_config_value('EnableRollNumber')
      sorting_method =  Configuration.get_config_value('StudentSortMethod')
      if (roll_number_enable == "0" and sorting_method == "roll_number") or sorting_method.nil?
        field = Configuration.set_value('StudentSortMethod', "first_name")
      end
    end
    
    def get_sort_config
      config = Configuration.find_or_create_by_config_key('StudentSortMethod')
      config = Configuration.set_value('StudentSortMethod', "first_name") if config.config_value.nil?
      return config.config_value
    end
  end

  private
  def update_exam_group_date
    group = self.exam_group
    group.update_attribute(:exam_date, self.start_time.to_date) if !group.exam_date.nil? and self.start_time.to_date < group.exam_date
  end

  def create_exam_event
    if self.event.blank?
      #      new_event = Event.create do |e|
      #        e.title       = "#{t('exam_text')}"
      #        e.description = "#{self.exam_group.name} #{t('for')} #{self.subject.batch.full_name} - #{self.subject.name}"
      #        e.start_date  = self.start_time
      #        e.end_date    = self.end_time
      #        e.is_exam     = true
      #        e.origin      = self
      #      end
      #      batch_event = BatchEvent.create do |be|
      #        be.event_id = new_event.id
      #        be.batch_id = self.exam_group.batch_id
      #      end
      batch = Batch.find("#{self.exam_group.batch_id}")
      params = {:event => {:title => "#{t('exam_text')}", :description => "#{self.exam_group.name} #{t('for')} #{self.subject.batch.full_name} - #{self.subject.name}",:is_common => false, :start_date => self.start_time, :end_date => self.end_time, :is_exam => true, :origin => self, :batch_events_attributes =>{1=>{:batch_id => batch.id, :selected => "1"}}}}
      #self.event_id = new_event.id
      new = Event.new(params[:event])
      new.save
      self.update_attributes(:event_id=>new.id)
    end
  end

  def update_exam_event
    self.event.update_attributes(:start_date => self.start_time, :end_date => self.end_time, :description => "#{self.exam_group.name} #{t('for')} #{self.subject.batch.full_name} - #{self.subject.name}") unless self.event.blank?
  end

  def self.fetch_student_ranking_per_subject_data(params)
    student_ranking_per_subject params
  end

  def self.fetch_student_ranking_per_batch_data(params)
    student_ranking_per_batch params
  end

  def self.fetch_student_ranking_per_course_data(params)
    student_ranking_per_course params
  end

  def self.fetch_student_ranking_per_school_data(params)
    student_ranking_per_school(params)
  end

  def self.fetch_student_ranking_per_attendance_data(params)
    student_ranking_per_attendance params
  end

  def self.fetch_subject_wise_data(params)
    subject_wise_data params
  end

  def self.fetch_consolidated_exam_data(params)
    consolidated_exam_data params
  end

  def subject_user_ids?
    subject.employees.collect(&:user_id)
  end

end
