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

class SmsSetting < ActiveRecord::Base

  def application_sms_active
    application_sms = SmsSetting.find_by_settings_key("ApplicationEnabled")
    return (application_sms.present? ? application_sms.is_enabled : false)
  end

  def student_sms_active
    student_sms = SmsSetting.find_by_settings_key("StudentSmsEnabled")
    return (student_sms.present? ? student_sms.is_enabled : false)
  end

  def student_admission_sms_active
    student_sms = SmsSetting.find_by_settings_key("StudentAdmissionEnabled")
    return (student_sms.present? ? student_sms.is_enabled : false)
  end

  def parent_sms_active
    parent_sms = SmsSetting.find_by_settings_key("ParentSmsEnabled")
    return (parent_sms.present? ? parent_sms.is_enabled : false)
  end

  def employee_sms_active
    employee_sms = SmsSetting.find_by_settings_key("EmployeeSmsEnabled")
    return (employee_sms.present? ? employee_sms.is_enabled : false )
  end

  def attendance_sms_active
    attendance_sms = SmsSetting.find_by_settings_key("AttendanceEnabled")
    return (attendance_sms.present? ? attendance_sms.is_enabled : false)
  end

  def event_news_sms_active
    event_news_sms = SmsSetting.find_by_settings_key("NewsEventsEnabled")
    return (event_news_sms.present? ? event_news_sms.is_enabled : false)
  end

  def fee_submission_sms_active
    fee_submission_sms = SmsSetting.find_by_settings_key("FeeSubmissionEnabled")
    return (fee_submission_sms.present? ? fee_submission_sms.is_enabled : false)
  end

  def exam_result_schedule_sms_active
    result_schedule_sms = SmsSetting.find_by_settings_key("ExamScheduleResultEnabled")
    return (result_schedule_sms.present? ? result_schedule_sms.is_enabled : false)
  end
  
  def timetable_swap_sms_active
    timetable_swap_sms = SmsSetting.find_by_settings_key("TimetableSwapEnabled")
    return (timetable_swap_sms.present? ? timetable_swap_sms.is_enabled : false)
  end  
  
  def self.get_sms_config
    if File.exists?("#{Rails.root}/config/sms_settings.yml")
      config = YAML.load_file(File.join(Rails.root,"config","sms_settings.yml"))
    end
    return config
  end

  def self.application_sms_status
    application_sms = SmsSetting.find_by_settings_key("ApplicationEnabled")
    return (application_sms.present? ? application_sms.is_enabled : false)
  end
  
  def self.create_or_update key, value
    sms_setting = SmsSetting.find_or_create_by_settings_key({:settings_key => key, :is_enabled => value })    
    SmsSetting.update(sms_setting.id,:is_enabled=>value) if sms_setting.is_enabled != value
  end
  
  def delayed_sms_notification_active
    delayed_sms_notification = SmsSetting.find_by_settings_key("DelayedSMSNotificationEnabled")
    return (delayed_sms_notification.present? ? delayed_sms_notification.is_enabled : false)
  end
  
  def self.get_settings_for(setting_key)
    settings = SmsSetting.all(:conditions=>["settings_key= ?",setting_key])
    settings = settings.each_with_object({}){|setting,h| h[setting.user_type] = setting.is_enabled }
    return settings
  end
  
end
