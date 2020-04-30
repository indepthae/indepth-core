require 'i18n'
class DelayedSendSmsAbsenteesSubjectwise
  include ApplicationHelper
  def initialize(student_ids,date,subject_ids)
    @abs_rec = SubjectLeave.find_all_by_student_id_and_month_date_and_subject_id(student_ids,date,subject_ids)
  end
    
  def perform
    sms_setting = SmsSetting.new()
    if sms_setting.student_sms_active
        @abs_rec.each do |rec| 
            if rec.student.is_sms_enabled
              student_message = rec.sms_content_student_subject_wise
              recipients = []
              recipients.push rec.student.phone2.split(',') if rec.student.phone2.present?
              if recipients.present?
                recipients.flatten!
                recipients.uniq!
                SmsManager.new(student_message,recipients).perform
                    rec.notification_sent = 1
                    rec.save
              end
            end
        end
      end
      if sms_setting.parent_sms_active
        @abs_rec.each do |rec|
            if rec.student.immediate_contact.present? and rec.student.is_sms_enabled
              guardian_message = rec.sms_content_guardian_subject_wise
              guardian = rec.student.immediate_contact
              recipients = []
              recipients.push guardian.mobile_phone.split(',') if guardian.mobile_phone.present?
              if recipients.present?
                recipients.flatten!
                recipients.uniq!
                SmsManager.new(guardian_message,recipients).perform
                    rec.notification_sent = 1
                    rec.save
              end
            end
        end
      end
  end
  
  def initialize_with_school_id(student_ids,date,subject_ids)
    @school_id = MultiSchool.current_school.id
    initialize_without_school_id(student_ids,date,subject_ids)
  end
  
  alias_method_chain :initialize,:school_id
  
  
  def perform_with_school_id
    MultiSchool.current_school = School.find(@school_id)
    perform_without_school_id
  end
  
  alias_method_chain :perform,:school_id
  
end
