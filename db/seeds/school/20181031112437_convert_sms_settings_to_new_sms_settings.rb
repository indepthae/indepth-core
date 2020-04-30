if SmsSetting.exists?
  collected_sms_settings_ids = []
  all_sms_settings = SmsSetting.all
  students_sms_enabled = all_sms_settings.find_by_settings_key("StudentSmsEnabled")
  parents_sms_enabled = all_sms_settings.find_by_settings_key("ParentSmsEnabled")
  employees_sms_enabled = all_sms_settings.find_by_settings_key("EmployeeSmsEnabled")


  if students_sms_enabled.present? && parents_sms_enabled.present? && employees_sms_enabled.present?
    SmsSetting.transaction do
      collected_sms_settings_ids << students_sms_enabled.id
      collected_sms_settings_ids << parents_sms_enabled.id
      collected_sms_settings_ids << employees_sms_enabled.id
    
      #STUDENT ADMISSION
      student_admission_enabled = all_sms_settings.find_by_settings_key("StudentAdmissionEnabled")
      if student_admission_enabled.present?
        #permission present for student and guardian
        #STUDENT
        privilege_for_student = student_admission_enabled.clone
        privilege_for_student.user_type = "Student"
        if student_admission_enabled.is_enabled? && (!students_sms_enabled.is_enabled?) 
          privilege_for_student.is_enabled=false
        end
        privilege_for_student.save
     
        privilege_for_guardian = student_admission_enabled.clone
        privilege_for_guardian.user_type = "Guardian"
        if student_admission_enabled.is_enabled? && (!parents_sms_enabled.is_enabled?) 
          privilege_for_guardian.is_enabled=false
        end
        privilege_for_guardian.save
      
        collected_sms_settings_ids << student_admission_enabled.id
      end

      #EMPLOYEE ADMISSION
      SmsSetting.find_or_create_by_settings_key(:settings_key=>"EmployeeAdmissionEnabled", :is_enabled=>true, :user_type=>"Employee")
            
      #EXAM SCHEDULE
      exam_schedule_result_enabled = all_sms_settings.find_by_settings_key("ExamScheduleResultEnabled")
      if exam_schedule_result_enabled.present?
        #permission present for student and guardian
      
        #STUDENT
        privilege_for_student = exam_schedule_result_enabled.clone
        privilege_for_student.user_type = "Student"
        if exam_schedule_result_enabled.is_enabled? && (!students_sms_enabled.is_enabled?) 
          privilege_for_student.is_enabled=false
        end
        privilege_for_student.save
      
        #GUARDIAN
        privilege_for_guardian = exam_schedule_result_enabled.clone
        privilege_for_guardian.user_type = "Guardian"
        if exam_schedule_result_enabled.is_enabled? && (!parents_sms_enabled.is_enabled?) 
          privilege_for_guardian.is_enabled=false
        end
        privilege_for_guardian.save
      
        collected_sms_settings_ids << exam_schedule_result_enabled.id
      end



      #ATTENDANCE
      attendance_enabled = all_sms_settings.find_by_settings_key("AttendanceEnabled")
      if attendance_enabled.present?
        #permission present for student and guardian
      
        #STUDENT
        privilege_for_student = attendance_enabled.clone
        privilege_for_student.user_type = "Student"
        if attendance_enabled.is_enabled? && (!students_sms_enabled.is_enabled?) 
          privilege_for_student.is_enabled=false
        end
        privilege_for_student.save
      
        #GUARDIAN
        privilege_for_guardian = attendance_enabled.clone
        privilege_for_guardian.user_type = "Guardian"
        if attendance_enabled.is_enabled? && (!parents_sms_enabled.is_enabled?) 
          privilege_for_guardian.is_enabled=false
        end
        privilege_for_guardian.save
        collected_sms_settings_ids << attendance_enabled.id
      end

      # manual sms for attendance marking 
        SmsSetting.find_or_create_by_settings_key_and_user_type(:settings_key => "DelayedSMSNotificationEnabled" ,:is_enabled => false, :user_type=> nil)
      
      #TIMETABLE SWAP & CANCEL
      timetable_swap_enabled = all_sms_settings.find_by_settings_key("TimetableSwapEnabled")
      if timetable_swap_enabled.present?
        #permission present for student, guardian and employee
      
        #STUDENT
        privilege_for_student = timetable_swap_enabled.clone
        privilege_for_student.user_type = "Student"
        if timetable_swap_enabled.is_enabled? && (!students_sms_enabled.is_enabled?) 
          privilege_for_student.is_enabled=false
        end
        privilege_for_student.save
      
        #GUARDIAN
        privilege_for_guardian = timetable_swap_enabled.clone
        privilege_for_guardian.user_type = "Guardian"
        if timetable_swap_enabled.is_enabled? && (!parents_sms_enabled.is_enabled?) 
          privilege_for_guardian.is_enabled=false
        end
        privilege_for_guardian.save
      
        #EMPLOYEE
        privilege_for_employee = timetable_swap_enabled.clone
        privilege_for_employee.user_type = "Employee"
        if timetable_swap_enabled.is_enabled? && (!employees_sms_enabled.is_enabled?) 
          privilege_for_employee.is_enabled=false
        end
        privilege_for_employee.save
      
        collected_sms_settings_ids << timetable_swap_enabled.id
      else
        # as update or create is present for this setting -- this setting may not be present - in such case create manually
        SmsSetting.find_or_create_by_settings_key_and_user_type(:settings_key=>"TimetableSwapEnabled", :is_enabled=>false, :user_type=>"Student")
        SmsSetting.find_or_create_by_settings_key_and_user_type(:settings_key=>"TimetableSwapEnabled", :is_enabled=>false, :user_type=>"Guardian")
        SmsSetting.find_or_create_by_settings_key_and_user_type(:settings_key=>"TimetableSwapEnabled", :is_enabled=>false, :user_type=>"Employee")
      end


      #EVENTS
      news_events_enabled = all_sms_settings.find_by_settings_key("NewsEventsEnabled")
      if news_events_enabled.present?
        #permission present for student, guardian and employee
      
        #STUDENT
        privilege_for_student = news_events_enabled.clone
        privilege_for_student.user_type = "Student"
        if news_events_enabled.is_enabled? && (!students_sms_enabled.is_enabled?) 
          privilege_for_student.is_enabled=false
        end
        privilege_for_student.save
      
        #GUARDIAN
        privilege_for_guardian = news_events_enabled.clone
        privilege_for_guardian.user_type = "Guardian"
        if news_events_enabled.is_enabled? && (!parents_sms_enabled.is_enabled?) 
          privilege_for_guardian.is_enabled=false
        end
        privilege_for_guardian.save
      
        #EMPLOYEE
        privilege_for_employee = news_events_enabled.clone
        privilege_for_employee.user_type = "Employee"
        if news_events_enabled.is_enabled? && (!employees_sms_enabled.is_enabled?) 
          privilege_for_employee.is_enabled=false
        end
        privilege_for_employee.save
      
        collected_sms_settings_ids << news_events_enabled.id
      end


      #FEE SUBMISSION
      fee_submission_enabled = all_sms_settings.find_by_settings_key("FeeSubmissionEnabled")
      if fee_submission_enabled.present?
        #permission present for student, guardian and employee
      
        #STUDENT
        privilege_for_student = fee_submission_enabled.clone
        privilege_for_student.user_type = "Student"
        if fee_submission_enabled.is_enabled? && (!students_sms_enabled.is_enabled?) 
          privilege_for_student.is_enabled=false
        end
        privilege_for_student.save
      
        #GUARDIAN
        privilege_for_guardian = fee_submission_enabled.clone
        privilege_for_guardian.user_type = "Guardian"
        if fee_submission_enabled.is_enabled? && (!parents_sms_enabled.is_enabled?) 
          privilege_for_guardian.is_enabled=false
        end
        privilege_for_guardian.save
      
        #EMPLOYEE
        privilege_for_employee = fee_submission_enabled.clone
        privilege_for_employee.user_type = "Employee"
        if fee_submission_enabled.is_enabled? && (!employees_sms_enabled.is_enabled?) 
          privilege_for_employee.is_enabled=false
        end
        privilege_for_employee.save
      
        collected_sms_settings_ids << fee_submission_enabled.id
      end
    
      SmsSetting.destroy_all(["id in (?)",collected_sms_settings_ids])
    end
  end 

else
  [
    {:settings_key => "ApplicationEnabled" ,:is_enabled => false, :user_type=> nil},
    
    {:settings_key => "ResultPublishEnabled" ,:is_enabled => false, :user_type=> nil},
    
    {:settings_key=>"StudentAdmissionEnabled", :is_enabled=>false, :user_type=>"Student" },
    {:settings_key=>"StudentAdmissionEnabled", :is_enabled=>false, :user_type=>"Guardian" },
    
    {:settings_key=>"ExamScheduleResultEnabled", :is_enabled=>false, :user_type=>"Student" },
    {:settings_key=>"ExamScheduleResultEnabled", :is_enabled=>false, :user_type=>"Guardian" },
    
    {:settings_key=>"AttendanceEnabled", :is_enabled=>false, :user_type=>"Student" },
    {:settings_key=>"AttendanceEnabled", :is_enabled=>false, :user_type=>"Guardian" },
    
    {:settings_key=>"TimetableSwapEnabled", :is_enabled=>false, :user_type=>"Employee"},
    {:settings_key=>"TimetableSwapEnabled", :is_enabled=>false, :user_type=>"Student" },
    {:settings_key=>"TimetableSwapEnabled", :is_enabled=>false, :user_type=>"Guardian" },
    
    {:settings_key=>"NewsEventsEnabled", :is_enabled=>false, :user_type=>"Employee"},
    {:settings_key=>"NewsEventsEnabled", :is_enabled=>false, :user_type=>"Student" },
    {:settings_key=>"NewsEventsEnabled", :is_enabled=>false, :user_type=>"Guardian" },
    
    {:settings_key=>"FeeSubmissionEnabled", :is_enabled=>false, :user_type=>"Employee"},
    {:settings_key=>"FeeSubmissionEnabled", :is_enabled=>false, :user_type=>"Student" },
    {:settings_key=>"FeeSubmissionEnabled", :is_enabled=>false, :user_type=>"Guardian" },
    
    {:settings_key=>"EmployeeAdmissionEnabled", :is_enabled=>true, :user_type=> "Employee"},
    
    {:settings_key => "DelayedSMSNotificationEnabled" ,:is_enabled => false, :user_type=> nil}
  ].each do |param|
    SmsSetting.find_or_create_by_settings_key_and_user_type(param)
  end
  
end
  


