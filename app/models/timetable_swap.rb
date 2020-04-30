require 'logger'
class TimetableSwap < ActiveRecord::Base
  validates_uniqueness_of :date, :scope => [:timetable_entry_id, :employee_id,:subject_id], :message => "#{t('already_swapped_or_cancelled')}"
  validates_presence_of :timetable_entry_id
  belongs_to :employee
  belongs_to :subject
  belongs_to :timetable_entry
  before_save :present_subject_attendacne_check, :fetch_last_swap_data
  after_save :update_classroom_allocations
  before_update :swaped_subject_attendance_check
  before_destroy :swaped_subject_attendance_check
  after_destroy :update_deleted_classroom_allocations
  after_create :verify_and_send_sms, :send_reminders
  after_update :verify_and_send_sms, :send_reminders
  attr_accessor :alert_notify,  :email_texts, :old_swap_teacher, :old_swap_subject, :is_new_record, :prev_subject, :prev_employee
  
  def validate
    timetable_entry = TimetableEntry.find(self.timetable_entry_id)
    unless is_cancelled
      errors.add(:employee, :blank) unless self.employee_id.present?
      errors.add(:subject, :blank) unless self.subject_id.present?
    end
    if timetable_entry.employee_ids.include? self.employee_id and (timetable_entry.entry_id == self.subject_id and timetable_entry.entry_type == 'Subject')
      errors.add_to_base :same_employee_assigned
      return false
    else
      return true
    end
    
  end
  
  def fetch_last_swap_data
    unless new_record?
      self.old_swap_teacher = Employee.find(employee_id_was)
      self.old_swap_subject = Subject.find(subject_id_was)
    end
  end
  
  def update_classroom_allocations
    if self.is_cancelled
      allocated_rooms = timetable_entry.allocated_classrooms
      allocated_room = allocated_rooms.first if allocated_rooms.present?
      allocated_room.update_attribute(:is_deleted, true) if allocated_room.present?
    end
  end
  
  def update_deleted_classroom_allocations
    if self.is_cancelled
      allocated_rooms = timetable_entry.allocated_classrooms
      allocated_room = allocated_rooms.first if allocated_rooms.present?
      allocated_room.update_attribute(:is_deleted, false) if allocated_room.present?
    end
  end

  def present_subject_attendacne_check
    attendance_lock = AttendanceSetting.is_attendance_lock
    timetable_entry = TimetableEntry.find(self.timetable_entry_id)
    subject_leave= SubjectLeave.all(:conditions=>{:month_date=>self.date,:subject_id=>timetable_entry.entry_id,:class_timing_id=>timetable_entry.class_timing_id,:batch_id=>timetable_entry.batch_id})
    save_date = MarkedAttendanceRecord.all(:conditions=>{:attendance_type => 'SubjectWise',:month_date=>self.date,:subject_id=>timetable_entry.entry_id,:class_timing_id=>timetable_entry.class_timing_id,:batch_id=>timetable_entry.batch_id})
    if subject_leave.present? || (attendance_lock && save_date.present?)
      errors.add_to_base :present_subject_having_attendance
      return false
    else
      return true
    end
  end
  
  def swaped_subject_attendance_check
    attendance_lock = AttendanceSetting.is_attendance_lock
    timetable_swap=TimetableSwap.find self.id
    timetable_entry=timetable_swap.timetable_entry
    subject_leave= SubjectLeave.all(:conditions=>{:month_date=>timetable_swap.date,:subject_id=>timetable_swap.subject_id,:class_timing_id=>timetable_entry.class_timing_id,:batch_id=>timetable_entry.batch_id})
    save_date = MarkedAttendanceRecord.all(:conditions=>{:attendance_type => 'SubjectWise',:month_date=>self.date.to_date,:subject_id=>timetable_swap.subject_id,:class_timing_id=>timetable_entry.class_timing_id,:batch_id=>timetable_entry.batch_id})
    if subject_leave.present? || (attendance_lock && save_date.present?)
      errors.add_to_base :swaped_subject_having_attendance
      return false
    else
      return true
    end
  end
  
  def self.batch_swapped_timetable_entries(batch_id, month=nil)
    conditions = []
    conditions << "timetable_entries.batch_id = #{batch_id}" if batch_id.present?
    conditions << "month(date) = #{month}" if month.present?
    TimetableSwap.all(:joins => :timetable_entry, :conditions => conditions.join(" and "))
  end

  def send_reminders # Reminder for timetable period swap & cancel
    is_new_record = (created_at == updated_at)
    if alert_notify == 1
      tte = TimetableEntry.find(self.timetable_entry, :include => [{:batch => {:students => :immediate_contact}}, :employees])
      students = tte.batch.students
      student_users = students.map {|student| student.user_id}
      parents = students.present? ? tte.batch.students.map {|s| s.immediate_contact }.compact : []
      parent_users = parents.map {|parent| parent.user_id}
      teachers_list = []
      teachers_list = old_swap_teacher.present? ? old_swap_teacher.to_a : (tte.employees).dup.flatten
      #      teachers_list = (tte.employees).dup # if period was swapped
      teachers_list << self.employee if !self.is_cancelled #and employee_sms_active# no employee data for cancelled periods
      teacher_users = teachers_list.map {|emp| emp.user_id }.compact.uniq
            
      if teacher_users.present?
        content = is_cancelled ? t('timetable_period_cancel_reminder_body_employee', :subject_name => subject_name, :date => format_date(date),
          :start_time => start_time, :end_time => end_time, :old_teacher_name => teacher_first_name, :batch_name => tte.batch.full_name) :
          t('timetable_period_swap_reminder_body_employee',:subject_name => subject_name, :date => format_date(date),:start_time => start_time, 
          :end_time => end_time, :old_teacher_name => teacher_first_name, :batch_name => tte.batch.full_name, :new_subject_name => new_subject_name, :new_teacher_name => new_teacher_name)
        links = {:target=>'view_timetable',:target_param=>'employee_id'}
        inform(teacher_users,content,'Timetable',links)
      end
    
      if student_users.present?
        content = is_cancelled ? t('timetable_period_cancel_reminder_body_student', :subject_name => subject_name, :date => format_date(date),:start_time => start_time,
          :end_time => end_time, :old_teacher_name => teacher_first_name, :batch_name => tte.batch.full_name) : 
          t('timetable_period_swap_reminder_body_student',:subject_name => subject_name, :date => format_date(date),:start_time => start_time, 
          :end_time => end_time, :old_teacher_name => teacher_first_name, :batch_name => tte.batch.full_name, :new_subject_name => new_subject_name, :new_teacher_name => new_teacher_name)
        links = {:target=>'view_timetable',:target_param=>'student_id'}
        inform(student_users,content,'Timetable',links)
      end
    
      if parent_users.present?
        content = is_cancelled ? t('timetable_period_cancel_reminder_body_parent', :subject_name => subject_name, :date => format_date(date),:start_time => start_time, 
          :end_time => end_time, :old_teacher_name => teacher_first_name, :batch_name => tte.batch.full_name) : 
          t('timetable_period_swap_reminder_body_parent',:subject_name => subject_name, :date => format_date(date),:start_time => start_time, 
          :end_time => end_time, :old_teacher_name => teacher_first_name, :batch_name => tte.batch.full_name, :new_subject_name => new_subject_name, :new_teacher_name => new_teacher_name)
        #        links = {:target=>'view_timetable',:target_param=>'parent_id'}
        inform(parent_users,content,'Timetable')
      end
    end
  end
  
  def verify_and_send_sms
    if self.is_cancelled? 
      AutomatedMessageInitiator.class_cancel(self)
    else 
      AutomatedMessageInitiator.class_swap(self)
    end
  end
    
  def email_recipients_for_swap(recipient_type, is_update = false)
    recipients = []
    case recipient_type
    when 'parent'
      tte = TimetableEntry.find(self.timetable_entry, :include => [{:batch => {:students => :immediate_contact}}])
      students = tte.batch.students.map {|s| s.email if (s.is_email_enabled and s.email.present?) }.compact
      recipients = students.present? ? tte.batch.students.map {|s| [s.immediate_contact.email, s.immediate_contact.first_name] if s.immediate_contact.present? and s.immediate_contact.email.present?}.compact : []
    when 'employee'
      tte = TimetableEntry.find(self.timetable_entry, :include => :employees)
      teachers_list = []
      teachers_list = is_update ? old_swap_teacher.to_a : (tte.employees).dup.flatten #if self.is_cancelled
      teachers_list << self.employee #if self.is_cancelled # no employee data for cancelled periods
      recipients = teachers_list.flatten.compact.map {|e| [e.email, e.first_name] if e.email.present? }.compact
    else # default as student recipient type        
      tte = TimetableEntry.find(self.timetable_entry, :include => [{:batch => :students}])
      recipients = tte.batch.students.map {|s| [s.email, s.first_name] if (s.is_email_enabled and s.email.present?) }.compact
    end    
    recipients
  end
    
  def email_recipients_for_cancel(recipient_type)    
    recipients = []
    case recipient_type
    when "parent"
      tte = TimetableEntry.find(self.timetable_entry, :include => [{:batch => {:students => :immediate_contact}}])
      students = tte.batch.students.map {|s| s.email if (s.is_email_enabled and s.email.present?) }.compact
      parents_data = students.present? ? tte.batch.students.map {|s| [s.immediate_contact.email, s.immediate_contact.first_name] if s.immediate_contact.present? and s.immediate_contact.email.present?}.compact : []
      recipients = parents_data if parent.present?
    when "employee"
      tte = TimetableEntry.find(self.timetable_entry, :include => :employees)
      teachers_list = tte.employees.dup.flatten #if self.is_cancelled # no employee data for cancelled periods
      recipients = teachers_list.compact.map {|e| [e.email, e.first_name] if e.email.present? }.compact if teachers_list.present?
    else # default as student recipient type
      tte = TimetableEntry.find(self.timetable_entry, :include => [{:batch => :students}])
      recipients = tte.batch.students.map {|s| [s.email, s.first_name] if (s.is_email_enabled and s.email.present?) }.compact
    end
    recipients
  end
  
  def subject_name # old subject name
    email_attributes 'subject_name'
  end
  
  def batch_name
    email_attributes 'batch_name'
  end
  
  def new_subject_name
    email_attributes 'new_subject_name'
  end
  
  def start_time
    email_attributes 'start_time'
  end
  
  def end_time
    email_attributes 'end_time'
  end
  
  def teacher_first_name
    email_attributes 'teacher_first_name'
  end
  
  def old_teacher_name
    email_attributes 'old_teacher_name'
  end  
  
  def new_teacher_name
    email_attributes 'new_teacher_name'
  end
  
  def fedena_instance_url
    Fedena.hostname
  end
  
  def email_attributes attr    
    email_texts ||= {'date' => nil, 'end_time'=> nil, 'new_subject_name'=> nil, 'start_time'=> nil, 'subject_name'=> nil, 'old_teacher_name'=> nil, 'batch_name'=> nil, 'new_teacher_name'=> nil, 'current_url' => nil}
    unless email_texts[attr].present?
      tte = is_cancelled ? TimetableEntry.find(timetable_entry_id, :include => [:employees, :batch]) : TimetableEntry.find(timetable_entry_id, :include => [:entry, :employees, :batch, :class_timing, :batch])      
      subjectname = subject.name unless is_cancelled
      subjectname = Subject.find(prev_subject).try(:name) if is_cancelled and prev_subject.present?
      employeename = Employee.find(prev_employee).try(:first_name) if is_cancelled and prev_employee.present?
      batchname = tte.batch.name unless is_cancelled
      case attr
      when "current_url"
        email_texts['current_url'] = current_url
      when "batch_name"
        email_texts['batch_name'] = batchname || tte.batch.name
      when "date"
        email_texts['date'] = date
      when "start_time"
        email_texts['start_time'] = tte.class_timing.start_time.strftime("%I:%M %p")
      when "end_time"
        email_texts['end_time'] = tte.class_timing.end_time.strftime("%I:%M %p")
      when "new_subject_name"
        email_texts['new_subject_name'] = subjectname || subject.try(:name) || tte.timetable_entry.subjects.map(&:name)
      when "subject_name"
        email_texts['subject_name'] = old_swap_subject.present? ? old_swap_subject.name : tte.entry.name
      when "teacher_first_name"
        email_texts['teacher_first_name'] = old_swap_teacher.present? ? old_swap_teacher.first_name : tte.employees.map(&:first_name).join(',')
      when "old_teacher_name"
        email_texts['old_teacher_name'] = old_swap_teacher.present? ? old_swap_teacher.first_name : tte.employees.map(&:full_name).join(',')
      when "new_teacher_name"
        email_texts['new_teacher_name'] = employeename || employee.try(:first_name)
      end 
    end
    email_texts[attr]
  end
end
