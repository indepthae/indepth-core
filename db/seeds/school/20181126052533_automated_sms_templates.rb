
#AUTOMATED TEMPLATES 

MessageTemplate.transaction do
  
  # Student Admission 
  message_template = MessageTemplate.new(:template_name=> "Student Admission", :automated_template_name=>"student_admission" , :template_type=>"AUTOMATED" )
  #student - template
  student_content = message_template.build_student_template_content(:user_type => "Student")
  student_content.content =  "Student admission done for {{admitted_student}}. Username is {{username}}, password is {{password}}. Thanks!"
  #guardian - template
  guardian_content = message_template.build_guardian_template_content(:user_type => "Guardian")
  guardian_content.content = "Student admission done for {{admitted_student}}. Username is {{username}}, password is {{password}}. Thanks!"
  
  message_template.save
  
  
  #Set Emergency Contact
  message_template = MessageTemplate.new(:template_name=> "Emergency Contact Addition", :automated_template_name=>"set_emergency_contact" , :template_type=>"AUTOMATED" )
  #guardian - template
  guardian_content = message_template.build_guardian_template_content(:user_type => "Guardian")
  guardian_content.content = "You are added as an emergency contact for {{student_name}}. Your username is {{username}}, password is {{password}}. Thanks!"
  
  message_template.save
  
  #Employee Admission 
  message_template = MessageTemplate.new(:template_name=> "Employee Admission", :automated_template_name=>"employee_admission" , :template_type=>"AUTOMATED" )
  #employee - template
  employee_content = message_template.build_employee_template_content(:user_type => "Employee")
  employee_content.content = "Employee admission done for {{admitted_employee}}. Username is {{username}}, password is {{password}}. Thanks!"
  
  message_template.save
  
  
  #Change Student Immediate Contact
  message_template = MessageTemplate.new(:template_name=> "Student Immediate Contact Change", :automated_template_name=>"student_immediate_contact_changed" , :template_type=>"AUTOMATED" )
  #guardian - template
  guardian_content = message_template.build_guardian_template_content(:user_type => "Guardian")
  guardian_content.content = "You are added as an emergency contact for {{weird_name}}. Your username is {{username}}, password is {{password}}. Thanks!"
  
  message_template.save
  
  #Add Sibling
  message_template = MessageTemplate.new(:template_name=> "Sibling Addition", :automated_template_name=>"set_emergency_contact" , :template_type=>"AUTOMATED" )
  #student - template
  student_content = message_template.build_student_template_content(:user_type => "Guardian")
  student_content.content =  "You are added as an emergency contact for {{student_name}}. Your username is {{username}}, password is {{password}}. Thanks!"
  
  message_template.save
  
  
  #Exam Schedule Published
  message_template = MessageTemplate.new(:template_name=> "Exam Schedule Published", :automated_template_name=>"exam_schedule_published" , :template_type=>"AUTOMATED" )
  #student - template
  student_content = message_template.build_student_template_content(:user_type => "Student")
  student_content.content =  "Exam schedule is published for {{exam_name}}. Thanks!"
  #guardian - template
  guardian_content = message_template.build_guardian_template_content(:user_type => "Guardian")
  guardian_content.content = "Exam schedule is published for {{exam_name}}. Thanks!"
  
  message_template.save
  
  
  #Exam Result Published
  message_template = MessageTemplate.new(:template_name=> "Exam Result Published", :automated_template_name=>"exam_result_published" , :template_type=>"AUTOMATED" )
  #student - template
  student_content = message_template.build_student_template_content(:user_type => "Student")
  student_content.content =  "Exam result is published for {{exam_name}}. Thanks!"
  #guardian - template
  guardian_content = message_template.build_guardian_template_content(:user_type => "Guardian")
  guardian_content.content = "Exam result is published for {{exam_name}}. Thanks!"
  
  message_template.save
  
  #Event 
  message_template = MessageTemplate.new(:template_name=> "Event", :automated_template_name=>"event" , :template_type=>"AUTOMATED" )
  #student - template
  student_content = message_template.build_student_template_content(:user_type => "Student")
  student_content.content =  "Event {{event_name}} is scheduled from {{start_time}} to {{end_time}}. Thanks!"
  #employee - template
  employee_content = message_template.build_employee_template_content(:user_type => "Employee")
  employee_content.content = "Event {{event_name}} is scheduled from {{start_time}} to {{end_time}}. Thanks!"
  #guardian - template
  guardian_content = message_template.build_guardian_template_content(:user_type => "Guardian")
  guardian_content.content = "Event {{event_name}} is scheduled from {{start_time}} to {{end_time}}. Thanks!"
  
  message_template.save
  
  #Fee Submission
  message_template = MessageTemplate.new(:template_name=> "Fee Submission", :automated_template_name=>"fee_submission" , :template_type=>"AUTOMATED" )
  #student - template
  student_content = message_template.build_student_template_content(:user_type => "Student")
  student_content.content =  "Dear {{student_full_name}}, we received {{fees_amount}} towards {{fee_collection_name}} dated {{transaction_date}} . Thanks!"
  #employee - template
  employee_content = message_template.build_employee_template_content(:user_type => "Employee")
  employee_content.content =  "Dear {{employee_full_name}}, we received {{fees_amount}} towards {{fee_collection_name}} dated {{transaction_date}} . Thanks!"
  #guardian - template
  guardian_content = message_template.build_guardian_template_content(:user_type => "Guardian")
  guardian_content.content = "Dear {{guardian_full_name}}, we received {{fees_amount}} towards {{fee_collection_name}} dated {{transaction_date}} . Thanks!"
  
  message_template.save
  
  
  #Fee Due 
  message_template = MessageTemplate.new(:template_name=> "Fee Due", :automated_template_name=>"fee_due" , :template_type=>"AUTOMATED" )
  #student - template 
  student_content = message_template.build_student_template_content(:user_type => "Student")
  student_content.content =  "Hi {{student_first_name}}, you have {{currency}}{{balance_fee}} of fee due as on {{date}}. Additional fine may be applicable. Ignore if already paid. Thanks!"
  #guardian - template
  guardian_content = message_template.build_guardian_template_content(:user_type => "Guardian")
  guardian_content.content = "Dear Parent, your ward {{ward_full_name}} has {{currency}} {{ward_balance_fee}} of fee due as on {{date}}. Additional fine may be applicable. Ignore if already paid. Thanks!" 
  
  message_template.save
  
  
  #Class Swap - 1
  message_template = MessageTemplate.new(:template_name=> "Class Swap1", :automated_template_name=>"class_swap1" , :template_type=>"AUTOMATED" )
  #student - template
  student_content = message_template.build_student_template_content(:user_type => "Student")
  student_content.content =  "Your scheduled subject {{scheduled_subject}} on {{scheduled_date}} from {{class_timing_name_from}} to {{class_timing_name_to}} for {{batch_name}} is replaced with {{swapped_subject}} by {{swapped_teacher}}. Thanks"
  #employee - template
  employee_content = message_template.build_employee_template_content(:user_type => "Employee")
  employee_content.content = "Subject {{scheduled_subject}} scheduled on {{scheduled_date}} from {{class_timing_name_from}} to {{class_timing_name_to}} for {{batch_name}} by {{scheduled_teacher}} is replaced with {{swapped_subject}} by {{swapped_teacher}}. Thanks"
  #guardian - template
  guardian_content = message_template.build_guardian_template_content(:user_type => "Guardian")
  guardian_content.content =  "Scheduled subject {{scheduled_subject}} on {{scheduled_date}} from {{class_timing_name_from}} to {{class_timing_name_to}} for {{batch_name}} is replaced with {{swapped_subject}} by {{swapped_teacher}}. Thanks"
  message_template.save
  
  
  #Class Swap - 2
  message_template = MessageTemplate.new(:template_name=> "Class Swap2", :automated_template_name=>"class_swap2" , :template_type=>"AUTOMATED" )
  #employee - template
  employee_content = message_template.build_employee_template_content(:user_type => "Employee")
  employee_content.content = "You are scheduled for {{swapped_subject}} on {{scheduled_date}} from {{class_timing_name_from}} to {{class_timing_name_to}} for {{batch_name}} in place of {{scheduled_subject}} by {{scheduled_teacher}}. Thanks"
  
  message_template.save
  
  
  #Class Cancel
  message_template = MessageTemplate.new(:template_name=> "Class Cancel", :automated_template_name=>"class_cancel" , :template_type=>"AUTOMATED" )
  #student - template
  student_content = message_template.build_student_template_content(:user_type => "Student")
  student_content.content =  "{{subject_name}} scheduled for {{batch_name}} on {{date}} from {{class_timing_name_from}}  to {{class_timing_name_to}} for {{teacher_name}} is cancelled. Thanks"
  #employee - template
  employee_content = message_template.build_employee_template_content(:user_type => "Employee")
  employee_content.content = "Your subject {{subject_name}} scheduled for {{batch_name}} on {{date}} from {{class_timing_name_from}} to {{class_timing_name_to}} is cancelled. Thanks"
  #guardian - template
  guardian_content = message_template.build_guardian_template_content(:user_type => "Guardian")
  guardian_content.content = "{{subject_name}} scheduled for {{batch_name}} on {{date}} from {{class_timing_name_from}}  to {{class_timing_name_to}} for {{teacher_name}} is cancelled. Thanks"
  
  message_template.save
  
  
  #Subject wise Attendance
  message_template = MessageTemplate.new(:template_name=> "Subject wise Attendance", :automated_template_name=>"subject_wise_attendance" , :template_type=>"AUTOMATED" )
  #student - template
  student_content = message_template.build_student_template_content(:user_type => "Student")
  student_content.content =  "Hi, you are marked {{attendance_label}} on {{absent_date}} for subject {{subject_name}} during period {{class_timing_name}}. Thanks!"
  #guardian - template
  guardian_content = message_template.build_guardian_template_content(:user_type => "Guardian")
  guardian_content.content = "Your ward {{ward_full_name}} is {{attendance_label}} on {{absent_date}} for subject {{subject_name}} during period {{class_timing_name}}. Thanks!"
  
  message_template.save
  
# daily wise attedance
  message_template = MessageTemplate.new(:template_name=> "Daily wise Attendance", :automated_template_name=>"daily_wise_attendance" , :template_type=>"AUTOMATED" )
  #student - template
  student_content = message_template.build_student_template_content(:user_type => "Student")
  student_content.content =  "Hi, you are marked {{attendance_label}} on {{absent_date}} during {{timing}}. Thanks!"
  #guardian - template
  guardian_content = message_template.build_guardian_template_content(:user_type => "Guardian")
  guardian_content.content = "Your ward {{ward_full_name}} is {{attendance_label}} on {{absent_date}} during {{timing}}. Thanks!"
  
  message_template.save
  
  #Gradebook Schedule Exams
  message_template = MessageTemplate.new(:template_name=> "Gradebook Schedule Exams", :automated_template_name=>"gradebook_schedule_exams" , :template_type=>"AUTOMATED" )
  #student - template
  student_content = message_template.build_student_template_content(:user_type => "Student")
  student_content.content =  "Exam {{exam_name}} is scheduled {{exam_schedule}} "
  #guardian - template
  guardian_content = message_template.build_guardian_template_content(:user_type => "Guardian")
  guardian_content.content = "Exam {{exam_name}} is scheduled {{exam_schedule}} "
  
  message_template.save
  
  #Gradebook Publish Exams
  message_template = MessageTemplate.new(:template_name=> "Gradebook Publish Results", :automated_template_name=>"gradebook_publish_results" , :template_type=>"AUTOMATED" )
  #student - template
  student_content = message_template.build_student_template_content(:user_type => "Student")
  student_content.content =  "Results for {{exam_name}} published. Student: {{student_full_name}} {{exam_results}}"
  #guardian - template
  guardian_content = message_template.build_guardian_template_content(:user_type => "Guardian")
  guardian_content.content = "Results for {{exam_name}} published. Student: {{ward_full_name}} {{exam_results}}"
  
  message_template.save
  
  
end
