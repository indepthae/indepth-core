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

class Reminder < ActiveRecord::Base
  include CsvExportMod
  validates_presence_of :body,:sender,:recipient,:subject
  belongs_to :user , :foreign_key => 'sender'
  belongs_to :to_user, :class_name=>"User",:foreign_key => 'recipient'
  has_many :reminder_attachments,:dependent=> :destroy,:through=>:reminder_attachment_relations
  has_many :reminder_attachment_relations,:dependent=>:destroy
  accepts_nested_attributes_for :reminder_attachments  , :allow_destroy => true ,:reject_if => lambda { |a| a[:attachment].blank? }
  xss_terminate :sanitize => [:body]
  cattr_reader :per_page
  attr_accessor :redactor_to_update, :redactor_to_delete
  @@per_page = 12

  def self.send_message(recipients_array,sender,end_date,elective)
    Delayed::Job.enqueue(DelayedReminderJob.new( :sender_id  => sender,
            :recipient_ids => recipients_array,
            :subject=> "Choose Elective",
            :body=> "Electives for group #{elective} are available.Please select it on or before #{end_date} "))
  end
  def self.send_message_to_list(sender,recipients_array,subject,body)
    return false if recipients_array.nil? || recipients_array.empty?
    recipients_array.each do |recipient|
      user=User.find_by_id(recipient)
      Reminder.create(:sender => sender,:recipient =>recipient,:subject => subject,:body => body)
    end
  end
  def self.send_message_to_list_with_attachments(sender,recipients_array,subject,body,attachments_list)
    return false if recipients_array.nil? || recipients_array.empty?
    attachments=ReminderAttachment.find(attachments_list)
    recipients_array.each do |recipient|
      user=User.find_by_id(recipient)
      reminder=Reminder.new
      reminder.subject=subject
      reminder.body=body
      reminder.sender = sender
      reminder.recipient =recipient
      reminder.save
      reminder.reminder_attachments=attachments
    end
  end
  def update_redactor
    RedactorUpload.update_redactors(self.redactor_to_update,self.redactor_to_delete)
  end

  def delete_redactors
    RedactorUpload.delete_after_create(self.content)
  end
  
  def self.fetch_reminder_data(params)
  	reminder_data params
  end
  
  # TODO refractor this method
  def self.get_departments_batches_and_parents(user)
    if user.admin?
      departments = EmployeeDepartment.active.ordered(:select=>'employee_departments.*, count(employees.id) as emp_count',:joins=>:employees,:group=>"employee_departments.id",:having=>"emp_count>0")
      batches=Batch.active(:select=>'batches.*, count(students.id) as stu_count,courses.code',:joins=>[:students,:course],:group=>"batches.id",:having=>"stu_count>0",:conditions=>["batches.is_deleted = ? and batches.is_active = ?",false,true],:order=>"courses.code ASC")
      parents_for_batch =Batch.active(:select=>'batches.*, count(students.id) as stu_count,courses.code,count(guardians.id) as guard_count',:joins=>[[:students=>:guardians],:course],:group=>"batches.id",:having=>"stu_count>0 and guard_count>0",:conditions=>["batches.is_deleted = ? and batches.is_active = ?",false,true],:order=>"courses.code ASC")
    elsif user.student?
      student=user.student_entry
      batches=student.batch.to_a
      parents_for_batch=student.batch.to_a if student.immediate_contact.present?
      departments=[]
      if student.batch.employees.present?
        student.batch.employees.each do |employee|
          departments<<employee.employee_department
        end
      end
      if student.subjects.active.present?
        student.subjects.active.each do |subject|
          if subject.employees.present?
            subject.employees.each do |employee|
              departments<<employee.employee_department
            end
          end
        end
      end
      if student.batch.subjects.active.present?
        student.batch.subjects.active.all(:conditions=>["elective_group_id IS NULL"]).each do |subject|
          if subject.employees.present? and subject.batch_id==student.batch_id
            subject.employees.each do |employee|
              departments<<employee.employee_department
            end
          end
        end
      end
      departments.uniq!
    elsif user.parent?
      students=Student.find_all_by_sibling_id(Guardian.find_by_user_id(user.id).ward_id)
      batches=[]
      subjects=[]
      batches=[]
      subjects=[]
      normal_subjects=[]
      if students.present?
        students.each do |student|
          batches+=student.batch.to_a
          subjects+=student.subjects.active
          normal_subjects+=student.batch.subjects.active.all(:conditions=>["elective_group_id IS NULL"])
        end
      end
      batches.uniq!
      subjects.uniq!
      normal_subjects.uniq!
      parents=[]
      departments=[]
      if batches.present?
        batches.each do |batch|
          if batch.employees.present?
            batch.employees.each do |employee|
              departments<<employee.employee_department
            end
          end
        end
      end
      if subjects.present?
        subjects.each do |subject|
          if subject.employees.present?
            subject.employees.each do |employee|
              departments<<employee.employee_department
            end
          end
        end
      end
      if normal_subjects.present?
        normal_subjects.each do |subject|
          if subject.employees.present?
            subject.employees.each do |employee|
              departments<<employee.employee_department
            end
          end
        end
      end
      departments.uniq!
      departments=departments.sort_by(&:name)
    elsif user.employee?
      if user.has_required_control?
        departments = EmployeeDepartment.active.ordered(:select=>'employee_departments.*, count(employees.id) as emp_count',:joins=>:employees,:group=>"employee_departments.id",:having=>"emp_count>0")
        batches=Batch.active(:select=>'batches.*, count(students.id) as stu_count,courses.code',:joins=>[:students,:course],:group=>"batches.id",:having=>"stu_count>0",:conditions=>["batches.is_deleted = ? and batches.is_active = ?",false,true],:order=>"courses.code ASC")
        parents_for_batch=[]
        if user.employee_record.subjects.active.present?
          user.employee_record.subjects.active.each do |subject|
            subject.batch.students.each do |student|
              parents_for_batch<<student.batch unless student.immediate_contact.nil?
            end
          end
        end
        if user.employee_record.batches.present?
          user.employee_record.batches.each do |batch|
            batch.students.each do |student|
              parents_for_batch<<student.batch unless student.immediate_contact.nil?
            end
          end
        end
        parents_for_batch.uniq!
      else
        departments = EmployeeDepartment.active.ordered(:select=>'employee_departments.*, count(employees.id) as emp_count',:joins=>:employees,:group=>"employee_departments.id",:having=>"emp_count>0")
        batches=Batch.active(:select=>'batches.*, count(students.id) as stu_count,courses.code',:joins=>[:students,:course],:group=>"batches.id",:having=>"stu_count>0",:conditions=>["batches.is_deleted = ? and batches.is_active = ?",false,true],:order=>"courses.code ASC")
      end
    end
    return departments,batches,parents_for_batch
  end
  def has_attachment?
    self.reminder_attachments.present?
  end
  def read?
    is_read == true
  end
end
