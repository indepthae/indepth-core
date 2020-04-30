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
class SubjectLeave < ActiveRecord::Base
  belongs_to :student
  belongs_to :batch
  belongs_to :subject
  belongs_to :employee
  belongs_to :class_timing
  belongs_to  :attendance_label

  has_and_belongs_to_many :employees, :join_table => "subject_leaves_teachers"
  #  attr_accessor :quick_mode
  attr_accessor :delay_notif

  validates_presence_of :subject_id
  validates_presence_of :attendance_label_id , :if => :validate_attendance_label
  validates_presence_of :batch_id
  validates_presence_of :student_id
  validates_presence_of :month_date
  validates_presence_of :class_timing_id
  #validates_presence_of :reason

  named_scope :by_month_and_subject, lambda { |d,s| { :conditions  => { :month_date  => d.beginning_of_month..d.end_of_month , :subject_id => s} } }
  named_scope :by_month_batch_subject, lambda { |d,b,s| {  :conditions  => { :month_date  => d.beginning_of_month..d.end_of_month , :subject_id => s,:batch_id=>b} } }

  named_scope :students_in_batches, lambda{|batch| {:conditions=>["student_id not in (?)",batch.batch_students.collect(&:student_id)]}}
  validates_uniqueness_of :student_id,:scope=>[:class_timing_id,:month_date] #,:message=> "#{t('attendance_already_marked_for_student')}" #"already marked as absent"
  
  after_create :verify_and_send_sms, :notify_student

  def validate
    unless student.nil?
      errors.add :attendance_before_the_date_of_admission  if (self.month_date < self.student.admission_date and Configuration.is_batch_date_attendance_config? == false) unless month_date.nil?
    end
    errors.add_to_base :future_attendance_cannot_be_marked if month_date > Configuration.default_time_zone_present_time.to_date
    timetable = Timetable.all(:conditions => ["start_date <= ? and end_date >= ? ",self.month_date, self.month_date]).last
    timetable_entry = TimetableEntry.find_by_timetable_id_and_class_timing_id_and_weekday_id_and_batch_id(timetable.id, self.class_timing_id, self.month_date.wday, self.batch_id) if timetable.present?    
    timetable_swap = TimetableSwap.find_by_timetable_entry_id_and_date(timetable_entry.id,month_date) if timetable_entry.present?    
    errors.add_to_base :timetable_swapped_for_period if timetable_swap.present? and timetable_swap.subject_id !=  self.subject_id
    errors.add_to_base :attendance_for_subject_not_valid if !timetable_swap.present? and timetable_entry.entry_type == 'Subject' and timetable_entry.entry_id !=  self.subject_id
    #    errors.add_to_base :attendance_for_subject_not_valid if !timetable_swap.present? and ((timetable_entry.entry_type == 'Subject' and timetable_entry.entry_id !=  self.subject_id) or (timetable_entry.entry_type == 'ElectiveGroup' and subject_ids.present? and subject_ids.include?(self.subject_id)))
    #    errors.add_to_base :attendance_for_subject_not_valid if !timetable_swap.present? and timetable_entry.entry_id !=  self.subject_id
  end

  def formatted_date
    format_date(month_date,:format=>:long)
  end

  def verify_and_send_sms
    custom_attendance_enable = Configuration.get_config_value('CustomAttendanceType') || "0"
    if  custom_attendance_enable == '1'
      validate_and_send_sms  if attendance_label_id.present? and attendance_label.has_notification == true
    else
      validate_and_send_sms
    end
  end
  
  def validate_and_send_sms
    sms_setting = SmsSetting.new()
    if sms_setting.delayed_sms_notification_active 
      if (self.delay_notif.to_s == "true") or (self.delay_notif.nil?)
        self.update_attribute(:notification_sent, false)
        return
      else
        send_sms
      end
    else
      send_sms
    end
  end
  
  
  def validate_email_setting
    if attendance_label_id.present? 
      if self.attendance_label.has_notification == true
        return true
      else
        return false
      end
    else
      return true
    end
  end
  
  def month_dates
    format_date(month_date,:format=>:long)
  end
   
  def reason_info
    if reason == ""
      return  'NA'
    else
      return reason
    end
  end
  
  def notify_student
    custom_attendance_enable = Configuration.get_config_value('CustomAttendanceType') || "0"
    user_ids = [student.user_id]
    user_ids << student.immediate_contact.user_id if student.immediate_contact.present?
    if  custom_attendance_enable == '1'
      if attendance_label_id.present? and attendance_label.has_notification == true
        body = t("attendance_notification_subject_wise",  :student_full_name => student.full_name,
          :student_admission_no => student.admission_no,:attendance_label_name => attendance_label_name, 
          :reason_info => reason_info,:month_date => month_dates, :subject_name =>  subject.name,:class_timing_name => class_timing.name)
        inform(user_ids, body, 'Attendance')
      end
    else
      body = t("attendance_notification_subject_wise",  :student_full_name => student.full_name,
        :student_admission_no => student.admission_no,:attendance_label_name => attendance_label_name, 
        :reason_info => reason_info, :subject_name =>  subject.name,:class_timing_name => class_timing.name, :month_date => month_dates)
      inform(user_ids, body, 'Attendance')
    end
  end
 
  def attendance_label_name
    if self.attendance_label_id.present?
      attendance_label = AttendanceLabel.find(self.attendance_label_id) 
      if  attendance_label.attendance_type == "Late"
        return 'Late'
      else
        return 'Absent'
      end
    else
      return 'Absent' 
    end
  end
   
  def validate_attendance_label
    @config = Configuration.get_config_value('CustomAttendanceType')|| "0"
    if @config == "1"
      return true
    else
      return false
    end
  end
  
  #  def sms_content_guardian_subject_wise
  #    unless Configuration.find_by_config_key('StudentAttendanceType').config_value=="Daily"
  #      guardian_message = "#{t('your_ward')} #{self.student.full_name}  #{t('is_for_attendance')} #{attendance_label_name}  #{t('on_for_attendance')} #{format_date(self.month_date)} #{t('for_subject')} #{self.subject.name} #{t('during_period')} #{self.class_timing.try(:name)}. #{t('thanks')}"
  #    end
  #    return guardian_message
  #  end
  #  
  #  def sms_content_student_subject_wise
  #    unless Configuration.find_by_config_key('StudentAttendanceType').config_value=="Daily"
  #      student_message = "#{t('hi_you_are_marked')} #{attendance_label_name} #{t('on_for_attendance')} #{format_date(self.month_date)} #{t('for_subject')} #{self.subject.name} #{t('during_period')} #{self.class_timing.try(:name)}. #{t('thanks')}"
  #    end
  #    return student_message
  #  end
  #  
  def send_sms 
    sms_setting = SmsSetting.new()
    student = self.student
    if sms_setting.application_sms_active and student.is_sms_enabled
      AutomatedMessageInitiator.subjectwise_attendance(self)  if Configuration.find_by_config_key('StudentAttendanceType').config_value=="SubjectWise"
    else
      self.update_attribute(:notification_sent, false)
    end
  end
  
  def self.fetch_attendance_data(student,batch,academic_days,month_date,end_date)
    attendance_label_id = AttendanceLabel.find_by_attendance_type('Absent').try(:id)
    student_attendance = SubjectLeave.find(:all,:select=>"(#{academic_days}-count(DISTINCT IF(subject_leaves.month_date BETWEEN '#{month_date}' AND 
    '#{end_date}' and (attendance_label_id is null or attendance_label_id = #{attendance_label_id}) and subject_leaves.batch_id=#{batch.id} ,subject_leaves.id,NULL))) as leaves,(#{academic_days}-count(DISTINCT 
     IF(subject_leaves.month_date BETWEEN '#{month_date}' AND '#{end_date}' and 
     subject_leaves.batch_id=#{batch.id},subject_leaves.id,NULL)))/#{academic_days}*100 as percent",
      :conditions=>{:batch_id=>batch.id,:student_id=>student.id_in_context}).first
    return student_attendance
  end
  
  def self.fetch_save_attendance_data(student_id,batch,academic_days)
    leaves = SubjectLeave.all(:conditions =>["student_id =? and batch_id=? and month_date IN (?)",student_id,batch.id,academic_days])
    leaves = leaves.to_a.reject{|sa| sa.attendance_label.try(:attendance_type) == "Late"}.count
    academic_days_count = (academic_days.count).to_f
    percent = academic_days.present? ? ((academic_days_count -leaves.to_f)/academic_days_count)*100 : 0
    persent_days = academic_days.present? ? (academic_days_count - leaves.to_f).to_f : 0
    return {"percent"=>percent,"leaves"=>persent_days,"academic_days"=>academic_days_count}
  end
  
  def self.attendance_status(batch_id,subject_id,dates)
    enable = Configuration.get_config_value('CustomAttendanceType')||"0"
    attendance_status = {}
    dates.each do |date|
      attendance_status[date[0]] = []
      attendance = SubjectLeave.find(:all,:conditions => ["batch_id = ? and month_date = ? and subject_id = ? ", batch_id,date[0],subject_id])
      attendance = attendance.to_a.reject{|ct| ct.attendance_label.try(:attendance_type) == "Late"} if (enable == '0')
      if attendance.present? 
        attendance.collect(&:class_timing_id).each do |ct|
          attendance_status[date[0]] << ct 
        end
      end
    end
    return attendance_status
  end
  
end
