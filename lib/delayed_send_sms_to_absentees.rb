require 'i18n'
class DelayedSendSmsToAbsentees
  attr_accessor :student_ids
  include ApplicationHelper
  def initialize(student_ids,date)
    @students = Student.find_all_by_id(student_ids)
    @date = date
  end
    
  def perform
    sms_setting = SmsSetting.new()
    if sms_setting.student_sms_active
        @students.each do |student|
            if student.is_sms_enabled
              student_message = student.student_sms_content(@date)
              recipients = []
              recipients.push student.phone2.split(',') if student.phone2.present?
              if recipients.present?
                recipients.flatten!
                recipients.uniq!
                SmsManager.new(student_message,recipients).perform
                    attendance = Attendance.find_by_student_id_and_month_date(student.id,@date)
                    attendance.notification_sent = 1
                    attendance.save
              end
            end
        end
      end
      if sms_setting.parent_sms_active
        @students.each do |student|
            if student.immediate_contact.present? and student.is_sms_enabled
              guardian_message = student.guardian_sms_content(@date)
              guardian = student.immediate_contact
              recipients = []
              recipients.push guardian.mobile_phone.split(',') if guardian.mobile_phone.present?
              if recipients.present?
                recipients.flatten!
                recipients.uniq!
                SmsManager.new(guardian_message,recipients).perform
                    attendance = Attendance.find_by_student_id_and_month_date(student.id,@date)
                    attendance.notification_sent = 1
                    attendance.save
              end
            end
        end
      end
  end
  
  def initialize_with_school_id(student_ids,date)
    @school_id = MultiSchool.current_school.id
    @date = date
    initialize_without_school_id(student_ids,date)
  end
  
  alias_method_chain :initialize,:school_id
  
  
  def perform_with_school_id
    MultiSchool.current_school = School.find(@school_id)
    perform_without_school_id
  end
  
  alias_method_chain :perform,:school_id
  
end
