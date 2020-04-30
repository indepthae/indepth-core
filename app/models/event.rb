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

class Event < ActiveRecord::Base
  validates_presence_of :title, :description, :start_date, :end_date

  named_scope :holidays, :conditions => {:is_holiday => true}
  named_scope :exams, :conditions => {:is_exam => true}
  has_many :batch_events, :dependent => :destroy
  has_many :employee_department_events, :dependent => :destroy
  has_many :user_events, :dependent => :destroy
  belongs_to :origin , :polymorphic => true

  attr_accessor :manual
  accepts_nested_attributes_for :user_events , :allow_destroy => true
  accepts_nested_attributes_for :batch_events, :allow_destroy => true, :reject_if => lambda { |l| l[:selected] == "0" }
  accepts_nested_attributes_for :employee_department_events, :allow_destroy => true, :reject_if => lambda { |l| l[:selected] == "0" }

  def verify_update_and_send_sms
    AutomatedMessageInitiator.event(self)  
  end

  def validate
    unless self.start_date.nil? or self.end_date.nil?
      errors.add(:end_time, :can_not_be_before_the_start_time) if self.end_date < self.start_date
    end
    unless self.origin.present?
      unless is_common
        selected_batches = batch_events.select{ |b| b.selected == "1" }
        selected_batches+= employee_department_events.select{ |d| d.selected == "1" }
        errors.add_to_base(:please_select_batch_or_department) unless selected_batches.present?
      else
        batch_events.each do |b|
          b.selected = "0"
        end
        employee_department_events.each do |d|
          d.selected = "0"
        end
      end
    end
    
  end
  
  def bulid_batches_and_departments
    build_batches()
    build_departments()
  end
  
  def build_batches
    batches = Batch.active
    batch_event_ids = batch_events.collect(&:batch_id)
    batches.each do |batch|
      unless batch_event_ids.include? batch.id
        batch_events.build(:batch_id => batch.id, :batch_name => batch.full_name, :selected => false)
      else
        batch_event = batch_events.detect{|b| b.batch_id == batch.id}
        batch_event.attributes = {:batch_name => batch.full_name, :selected => true}
      end
    end
  end
  
  def build_departments
    departments = EmployeeDepartment.active_and_ordered
    employee_department_ids = employee_department_events.collect(&:employee_department_id)
    departments.each do |department|
      unless employee_department_ids.include? department.id
        employee_department_events.build(:employee_department_id => department.id, :department_name => department.name, :selected => false)
      else
        employee_department = employee_department_events.detect{|d| d.employee_department_id == department.id}
        employee_department.attributes = {:department_name => department.name, :selected => true}
      end
    end
  end
    
  def is_student_event(student)
    flag = false
    base = self.origin
    unless base.blank?
      if base.respond_to?('batch_id')
        if (origin_type=="FinanceFeeCollection" and base.fee_collection_batches.collect(&:batch_id).include? student.batch_id) or base.batch_id == student.batch_id
          finance = base.fee_table
          if finance.present?
            flag = true if finance.map{|fee|fee.student_id}.include?(student.id)
          end
        end
      end
    end
    user_events = self.user_events
    unless user_events.nil?
      flag = true if user_events.map{|x|x.user_id }.include?(student.user.id)
    end
    return flag
  end

  def is_employee_event(user)
    user_events = self.user_events
    unless user_events.nil?
      return true if user_events.map{|x|x.user_id }.include?(user.id)
    end
    return false
  end

  def is_published_exam
    if self.origin_type == "Exam"
      return self.origin.exam_group.is_published if self.origin.present? and self.origin.exam_group.present?
    else self.origin_type == "SubjectAssessment"
      return true
    end
  end

  def is_active_event
    flag = false
    unless self.origin.nil?
      if self.origin.respond_to?('is_deleted')
        unless self.origin.is_deleted
          flag = true
        end
      else
        flag = true
      end 
    else
      flag = true
    end
    return flag
  end

  def dates
    (start_date.to_date..end_date.to_date).to_a
  end

  
  def event_member_emails
    member_email=[]

    if self.is_common
      EmployeeDepartment.active_and_ordered.each do |d| member_email=member_email+d.employees.collect(&:email).zip(d.employees.collect(&:first_name));end
      Batch.active.each do |d| member_email=member_email+d.students.select{|s| s.is_email_enabled?}.collect(&:email).zip(d.students.select{|s| s.is_email_enabled?}.collect(&:first_name));end
      Student.all.select{|s| s.is_email_enabled and s.immediate_contact.present? and s.immediate_contact.email.present?}.each do |st|
        member_email=member_email+st.immediate_contact.email.zip(st.immediate_contact.first_name)
      end
    end
    #member_email=member_email.flatten.reject{|e| e.empty?}
    return member_email
  end
  
  def event_days
    if (start_date.strftime "%a,%d %b %Y")== (end_date.strftime "%a,%d %b %Y")
      "#{format_date(start_date,:format=>:long_date)} #{format_date(start_date,:format=>:time)} to #{format_date(end_date,:format=>:time)}"
    else
      "#{format_date(start_date,:format=>:long)} to #{format_date(end_date,:format=>:long)}"
    end
  end

  def school_details
    name=Configuration.get_config_value('InstitutionName').present? ? "#{Configuration.get_config_value('InstitutionName')}," :""
    address=Configuration.get_config_value('InstitutionAddress').present? ? "#{Configuration.get_config_value('InstitutionAddress')}," :""
    Configuration.get_config_value('InstitutionPhoneNo').present?? phone="#{' Ph:'}#{Configuration.get_config_value('InstitutionPhoneNo')}" :""
    return (name+"#{' '}#{address}"+"#{phone}").chomp(',')
  end
  
  def school_name
    Configuration.get_config_value('InstitutionName')
  end
  
  class<< self
    def is_a_holiday?(day)
      return true if Event.holidays.count(:all, :conditions => ["start_date <=? AND end_date >= ?", day, day] ) > 0
      false
    end
    
    def create_event(params,id)
      reminder_recipient_ids,reminder_subject,reminder_body=confirm_event(id) 
      return reminder_recipient_ids,reminder_subject,reminder_body
    end
    
    def confirm_event(id)
      event = Event.find(id)
      config = Configuration.find_by_config_key('StudentAttendanceType')
      reminder_subject = "#{t('new_event')} : #{event.title}"
      reminder_body = "<b> #{event.title}</b> : #{event.description} #{t('start_date')} : " + format_date(event.start_date) + " #{t('end_date')} : " + format_date(event.end_date)
      reminder_recipient_ids = []
      if config.config_value == 'Daily'
        if event.is_common == true
          if event.is_holiday == true
            attendance=Attendance.find(:all, :conditions=>{:month_date => event.start_date.to_date..event.end_date.to_date})
            unless attendance.nil?
              attendance.each do |att|
                att.destroy
              end
            end
          end
          users = User.active.find(:all)
          reminder_recipient_ids << users.map(&:id)
        else
          batch_event_ids = BatchEvent.find_all_by_event_id(event.id).collect(&:batch_id)
          unless batch_event_ids.empty?
            if event.is_holiday == true
              attendance=Attendance.find(:all, :conditions => ["batch_id IN (?) and month_date >= ? and month_date <= ?", batch_event_ids.map { |v| v.to_i },event.start_date.to_date,event.end_date.to_date ] )
              unless attendance.nil?
                attendance.each do |att|
                  att.destroy
                end
              end
            end
            batch_students = Student.find(:all, :conditions=>["batch_id IN (?)", batch_event_ids.map { |v| v.to_i }])
            batch_students.each do |s|
              reminder_recipient_ids << s.user_id
              unless s.immediate_contact.nil?
                reminder_recipient_ids << s.immediate_contact.user_id
              end
            end
          end
          department_event = EmployeeDepartmentEvent.find_all_by_event_id(event.id)
          unless department_event.empty?
            department_event.each do |d|
              dept_emp = Employee.find(:all, :conditions=>"employee_department_id = #{d.employee_department_id}")
              dept_emp.each do |e|
                reminder_recipient_ids << e.user_id
              end
            end
          end
        end
      else
        if event.is_common == true
          if event.is_holiday == true
            attendance=SubjectLeave.find(:all,  :conditions =>{:month_date => event.start_date.to_date..event.end_date.to_date})
            unless attendance.nil?
              attendance.each do |att|
                att.destroy
              end
            end
          end
          users = User.active.find(:all)
          reminder_recipient_ids << users.map(&:id)
        else
          batch_event_ids = BatchEvent.find_all_by_event_id(event.id).collect(&:batch_id)
          unless batch_event_ids.empty?
            if event.is_holiday == true
              attendance=SubjectLeave.find(:all, :conditions => ["batch_id IN (?) and month_date >= ? and month_date <= ?", batch_event_ids.map { |v| v.to_i },event.start_date.to_date,event.end_date.to_date ] )
              unless attendance.nil?
                attendance.each do |att|
                  att.destroy
                end
              end
            end
            batch_students = Student.find(:all, :conditions=>["batch_id IN (?)", batch_event_ids.map { |v| v.to_i }])
            batch_students.each do |s|
              reminder_recipient_ids << s.user_id
              unless s.immediate_contact.nil?
                reminder_recipient_ids << s.immediate_contact.user_id
              end
            end
          end
          department_event = EmployeeDepartmentEvent.find_all_by_event_id(event.id)
          unless department_event.empty?
            department_event.each do |d|
              dept_emp = Employee.find(:all, :conditions=>"employee_department_id = #{d.employee_department_id}")
              dept_emp.each do |e|
                reminder_recipient_ids << e.user_id
              end
            end
          end
        end
      end
      return reminder_recipient_ids,reminder_subject,reminder_body
    end
    
    def check_attendance(params)
      start_date = params[:event][:start_date].to_date
      end_date = params[:event][:end_date].to_date
      @config = Configuration.find_by_config_key('StudentAttendanceType')
      if @config.config_value == 'Daily'
        if params[:event][:is_common] == "1"
          attendance=Attendance.find(:all, :conditions=>{:month_date => start_date..end_date})
        elsif params["event"]["batch_events_attributes"].present?
          batch_ids = []
          params["event"]["batch_events_attributes"].each do |k, v|
            if v["selected"] == "1"
              batch_ids << v["batch_id"]
            end
          end
          attendance=Attendance.find(:all, :conditions => ["batch_id IN (?) and month_date >= ? and month_date <= ?", batch_ids.map { |v| v.to_i },start_date,end_date ] )
        end
      else
        if params[:event][:is_common] == "1"
          attendance=SubjectLeave.find(:all,  :conditions =>{:month_date => start_date..end_date})
        elsif params["event"]["batch_events_attributes"].present?
          batch_ids = []
          params["event"]["batch_events_attributes"].each do |k, v|
            if v["selected"] == "1"
              batch_ids << v["batch_id"]
            end
          end
          attendance=SubjectLeave.find(:all, :conditions => ["batch_id IN (?) and month_date >= ? and month_date <= ?", batch_ids.map { |v| v.to_i },start_date,end_date ] )
        end
      end
      return attendance
    end
    
  end
  
end
