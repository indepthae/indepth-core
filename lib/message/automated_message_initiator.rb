
class AutomatedMessageInitiator
  # EXAM RESULT PUBLISHED ------------------------------------------------------------------------------------
  def self.exam_result_published(exam_group)
    if exam_schedule_published_initiation_allowed?(exam_group)
      exam_name = exam_group.name
      if exam_name.present?
        settings =  SmsSetting.get_settings_for("ExamScheduleResultEnabled")
        template_contents={}
        message_template = MessageTemplate.find_by_automated_template_name("exam_result_published")
        student_template_content = message_template.student_template_content.replace_automated_keys(:exam_result_published,{:exam_name=>exam_name})
        guardian_template_content = message_template.guardian_template_content.replace_automated_keys(:exam_result_published,{:exam_name=>exam_name})
        template_contents = {:student => student_template_content, :guardian=> guardian_template_content}
        recipients = exam_schedule_published_recipient_builder(exam_group,settings)
        SmsManager.send_template_based_messages(template_contents,recipients,{},true)
      end
    end
  end



  # EXAM SCHEDULE PUBLISHED ------------------------------------------------------------------------------------
  def self.exam_schedule_published(exam_group)
    if exam_schedule_published_initiation_allowed?(exam_group)
      settings =  SmsSetting.get_settings_for("ExamScheduleResultEnabled")
      recipients = exam_schedule_published_recipient_builder(exam_group,settings)
      template_contents = exam_schedule_published_contents_builder(exam_group,settings)
      SmsManager.send_template_based_messages(template_contents,recipients,{},true)
    end
  end

  def self.exam_schedule_published_recipient_builder(exam_group, settings)
    recipients = {}
    batch = exam_group.batch
    students = batch.students
    student_ids = students.map{|s| s.id}
    recipients[:student_ids] = student_ids if settings["Student"] == true
    recipients[:guardian_sids] = student_ids if settings["Guardian"] == true
    return recipients
  end


  def self.exam_schedule_published_contents_builder(exam_group, settings)
    template_contents={}
    message_template = MessageTemplate.find_by_automated_template_name("exam_schedule_published")
    keys_to_be_replaced = {:exam_name=>exam_group.name}

    if settings["Student"] == true
      student_template_content = message_template.student_template_content.replace_automated_keys(:exam_schedule_published, keys_to_be_replaced)
      template_contents[:student] = student_template_content
    end
    if settings["Guardian"] == true
      guardian_template_content = message_template.guardian_template_content.replace_automated_keys(:exam_schedule_published, keys_to_be_replaced)
      template_contents[:guardian] = guardian_template_content
    end
    template_contents = {:student => student_template_content, :guardian=> guardian_template_content}

    return template_contents
  end


  def self.exam_schedule_published_initiation_allowed?(exam_group)
    sms_setting = SmsSetting.new()
    if sms_setting.application_sms_active and sms_setting.exam_result_schedule_sms_active
      return true
    else
      return false
    end
  end


  #FEE SUBMISSION  ---------------------------------------------------------------------------------------------
  def self.fee_submission(transaction)
    if fee_submission_initiation_allowed?(transaction)
      settings = SmsSetting.get_settings_for("FeeSubmissionEnabled")
      recipients = fee_submission_recipient_builder(transaction, settings)
      template_contents = fee_submission_contents_builder(transaction, settings)
      SmsManager.send_template_based_messages(template_contents,recipients,{},true) 
    end
  end


  def self.fee_submission_recipient_builder(transaction, settings)
    recipients = {}
    payee = transaction.payee
    if payee.is_a? Student #or  Applicant
      if settings["Student"] == true
        recipients[:student_ids] = [payee.id]
      end
      if settings["Guardian"] == true
        recipients[:guardian_sids] = [payee.id]
      end
    elsif payee.is_a? Employee
      if settings["Employee"] == true
        recipients[:employee_ids] = [payee.id]
      end
    end
    return recipients
  end


  def self.fee_submission_contents_builder(transaction, settings)
    template_contents={}
    models = {'FinanceFee' => 'finance_fee_collection', 'HostelFee' => 'hostel_fee_collection', 'TransportFee' => 'transport_fee_collection',
      'InstantFee' => 'instant_fee_category', 'RegistrationCourse' => ''}
    message_template = MessageTemplate.find_by_automated_template_name("fee_submission")
    if transaction.transaction_type == 'SINGLE'
      transaction = transaction.finance_transactions.first
      case transaction.finance_type
      when 'InstantFee'
        collection_name = transaction.finance.instant_fee_category.present? ? transaction.finance.instant_fee_category.name : transaction.finance.custom_category
      when 'RegistrationCourse'
        collection_name = I18n.t('application_fees')
      else
        collection = transaction.finance.send(models[transaction.finance_type])
        collection_name = collection.name if collection.present?
      end
    else
      collection_name =  transaction.finance_transactions.collect(&:finance_name).join(',')
    end
    fees_amount = FedenaPrecision.set_and_modify_precision(transaction.amount.to_f)
    transaction_date = format_date(transaction.transaction_date)
    keys_to_be_replaced = {:fees_amount=>fees_amount, :transaction_date=>transaction_date, :fee_collection_name=> collection_name.to_s}
    if settings["Student"] == true
      template_contents[:student] = message_template.student_template_content.replace_automated_keys(:fee_submission, keys_to_be_replaced)
    end
    if settings["Guardian"] == true
      template_contents[:guardian] = message_template.guardian_template_content.replace_automated_keys(:fee_submission, keys_to_be_replaced)
    end
    if settings["Employee"] == true
      template_contents[:employee] = message_template.employee_template_content.replace_automated_keys(:fee_submission, keys_to_be_replaced)
    end
    return template_contents
  end

  def self.fee_submission_initiation_allowed?(transaction)
    models = {'FinanceFee' => 'finance_fee_collection', 'HostelFee' => 'hostel_fee_collection', 'TransportFee' => 'transport_fee_collection',
      'InstantFee' => 'instant_fee_category', 'RegistrationCourse' => ''}
    finance_types = fetch_finance_type(transaction)if transaction.finance_transactions.present?
    finance_types.each do |ft|
      @valid_finance_type = if models.keys.include?(ft)
                              true
                            else
                              false
                            end
    end
    sms_setting = SmsSetting.new()
    if sms_setting.application_sms_active and transaction.payee.present? and @valid_finance_type
      return true
    else
      return false
    end
  end
  
  def self.fetch_finance_type(transaction)
    finance_types = []
    transaction.finance_transactions.each do |ft|
      finance_types << ft.finance_type      
    end
    return finance_types.uniq
  end


  #STUDENT ADMISSION--------------------------------------------------------------------------------------------
  def self.student_admission(student)
    if student_admission_initiation_allowed?(student)
      settings = SmsSetting.get_settings_for("StudentAdmissionEnabled")
      recipients = student_admission_recipient_builder(student, settings)
      template_contents = student_admission_contents_builder(student, settings)
      SmsManager.send_template_based_messages(template_contents,recipients,{},true)
    end
  end

  def self.student_admission_recipient_builder(student, settings)
    recipients = {}
    if settings["Student"] == true
      recipients[:student_ids] = [student.id]
    end
    return recipients
  end

  def self.student_admission_contents_builder(student, settings)
    template_contents={}
    message_template = MessageTemplate.find_by_automated_template_name("student_admission")
    username = student.admission_no
    password = "#{student.admission_no}123"
    admitted_student = student.full_name
    keys_to_be_replaced = {:username=>username, :password=>password, :admitted_student=> admitted_student}
    if settings["Student"] == true
      template_contents[:student] = message_template.student_template_content.replace_automated_keys(:student_admission, keys_to_be_replaced)
    end
    return template_contents
  end

  def self.student_admission_initiation_allowed?(student)
    sms_setting = SmsSetting.new()
    if sms_setting.application_sms_active && student.phone2.present?
      return true
    else
      return false
    end
  end


  #EMPLOYEE ADMISSION------------------------------------------------------------------------------------------------
  def self.employee_admission(employee)
    if employee_admission_initiation_allowed?(employee)
      settings = SmsSetting.get_settings_for("EmployeeAdmissionEnabled")
      recipients = employee_admission_recipient_builder(employee, settings)
      template_contents = employee_admission_contents_builder(employee, settings)
      SmsManager.send_template_based_messages(template_contents,recipients,{},true)
    end
  end

  def self.employee_admission_recipient_builder(employee, settings)
    recipients = {}
    if settings["Employee"] == true
      recipients[:employee_ids] = [employee.id]
    end
    return recipients
  end

  def self.employee_admission_contents_builder(employee, settings)
    template_contents={}
    message_template = MessageTemplate.find_by_automated_template_name("employee_admission")
    admitted_employee = employee.full_name
    username = employee.employee_number
    password = "#{employee.employee_number}123"
    keys_to_be_replaced = {:username=>username, :password=>password, :admitted_employee=> admitted_employee}
    if settings["Employee"] == true
      template_contents[:employee] = message_template.employee_template_content.replace_automated_keys(:employee_admission, keys_to_be_replaced)
    end
    return template_contents
  end

  def self.employee_admission_initiation_allowed?(employee)
    sms_setting = SmsSetting.new()
    if sms_setting.application_sms_active and employee.mobile_phone.present?
      return true
    else
      return false
    end
  end

  #DAILY WISE ATTENDANCE
  def self.dailywise_attendance(attendance)
    if attendance_initiation_allowed?
      settings = SmsSetting.get_settings_for("AttendanceEnabled")
      recipients = dailywise_attendance_recipient_builder(attendance, settings)
      template_contents = dailywise_attendance_contents_builder(attendance, settings)
      SmsManager.send_template_based_messages(template_contents,recipients,{},true)
      attendance.update_attribute(:notification_sent, true)
    end
  end

  def self.dailywise_attendance_recipient_builder(attendance, settings)
    recipients = {}
    student = attendance.student
    if settings["Student"] == true
      recipients[:student_ids] = [student.id]
    end
    if settings["Guardian"] == true
      recipients[:guardian_sids] = [student.id]
    end
    return recipients
  end

  def self.dailywise_attendance_contents_builder(attendance, settings)
    template_contents={}
    message_template = MessageTemplate.find_by_automated_template_name("daily_wise_attendance")
    absent_date = format_date(attendance.month_date)
    timing = is_full_day(attendance)
    attendance_label = attendance.attendance_label_id.present? ? attendance.attendance_label.name : "Absent"
    keys_to_be_replaced = {:attendance_label => attendance_label, :absent_date=>absent_date, :timing => timing}
    if settings["Student"] == true
      template_contents[:student] = message_template.student_template_content.replace_automated_keys(:daily_wise_attendance, keys_to_be_replaced)
    end
    if settings["Guardian"] == true
      template_contents[:guardian] = message_template.guardian_template_content.replace_automated_keys(:daily_wise_attendance, keys_to_be_replaced)
    end
    return template_contents
  end

  def self.is_full_day(attendance)
    if attendance.forenoon == true and attendance.afternoon == true
      return "full day"
    elsif attendance.forenoon
      return "Fore noon"
    elsif attendance.afternoon
      return "After noon"
    end
  end

  #SUBJECT WISE ATTENDANCE---------------------------------------------------------------------------------------------
  def self.subjectwise_attendance(subject_leave)
    if attendance_initiation_allowed?
      settings = SmsSetting.get_settings_for("AttendanceEnabled")
      recipients = subjectwise_attendance_recipient_builder(subject_leave, settings)
      template_contents = subjectwise_attendance_contents_builder(subject_leave, settings)
      SmsManager.send_template_based_messages(template_contents,recipients,{},true)
      subject_leave.update_attribute(:notification_sent, true)
    end
  end

  def self.subjectwise_attendance_recipient_builder(subject_leave, settings)
    recipients = {}
    student = subject_leave.student
    if settings["Student"] == true
      recipients[:student_ids] = [student.id]
    end
    if settings["Guardian"] == true
      recipients[:guardian_sids] = [student.id]
    end
    return recipients
  end

  def self.subjectwise_attendance_contents_builder(subject_leave, settings)
    template_contents={}
    message_template = MessageTemplate.find_by_automated_template_name("subject_wise_attendance")
    absent_date = format_date(subject_leave.month_date)
    subject_name = subject_leave.subject.name
    class_timing_name =  subject_leave.class_timing.try(:name)
    attendance_label = subject_leave.attendance_label_id.present? ? subject_leave.attendance_label.name : "Absent"
    keys_to_be_replaced = {:attendance_label => attendance_label, :absent_date=>absent_date, :subject_name=>subject_name, :class_timing_name=> class_timing_name}
    if settings["Student"] == true
      template_contents[:student] = message_template.student_template_content.replace_automated_keys(:subject_wise_attendance, keys_to_be_replaced)
    end
    if settings["Guardian"] == true
      template_contents[:guardian] = message_template.guardian_template_content.replace_automated_keys(:subject_wise_attendance, keys_to_be_replaced)
    end
    return template_contents
  end

  def self.attendance_initiation_allowed?
    sms_setting = SmsSetting.new()
    if sms_setting.application_sms_active 
      return true
    else
      return false
    end
  end


  #CLASS CANCEL-------------------------------------------------------------------------------------------------------
  def self.class_cancel(timetable_swap)
    if class_cancel_initiation_allowed?(timetable_swap)
      settings = SmsSetting.get_settings_for("TimetableSwapEnabled")
      recipients = class_cancel_recipient_builder(timetable_swap, settings)
      template_contents = class_cancel_contents_builder(timetable_swap, settings)
      SmsManager.send_template_based_messages(template_contents,recipients,{},true)
    end
  end

  def self.class_cancel_recipient_builder(timetable_swap, settings)
    is_new_record = (timetable_swap.created_at == timetable_swap.updated_at)
    tte = TimetableEntry.find(timetable_swap.timetable_entry, :include => [{:batch => :students }, :employees])
    students = tte.batch.students
    teachers_list_out = timetable_swap.old_swap_teacher.present? ? timetable_swap.old_swap_teacher.to_a : (tte.employees).dup.flatten
    teachers_list_in = (!timetable_swap.is_cancelled) ? timetable_swap.employee.to_a : []
    teachers_list_out = is_new_record ? teachers_list_out : ((teachers_list_out - teachers_list_in).to_a)

    recipients = {}
    if settings["Student"] == true
      recipients[:student_ids] =  students.collect(&:id)
    end
    if settings["Guardian"] == true
      recipients[:guardian_sids] = students.collect(&:id)
    end
    if settings["Employee"] == true
      recipients[:employee_ids] = teachers_list_out.collect(&:id)
    end
    return recipients
  end

  def self.class_cancel_contents_builder(timetable_swap, settings)
    template_contents={}
    message_template = MessageTemplate.find_by_automated_template_name("class_cancel")
    subject_name = timetable_swap.email_attributes('subject_name')
    batch_name = timetable_swap.email_attributes('batch_name')
    date = timetable_swap.date.to_s
    class_timing_name_from =  timetable_swap.email_attributes('start_time')
    class_timing_name_to =  timetable_swap.email_attributes('end_time')
    teacher_name = timetable_swap.email_attributes('teacher_first_name')
    keys_to_be_replaced = {:subject_name=>subject_name, :batch_name=>batch_name, :date=> date,
      :class_timing_name_from=> class_timing_name_from, :class_timing_name_to=> class_timing_name_to, :teacher_name=> teacher_name }
    if settings["Student"] == true
      template_contents[:student] = message_template.student_template_content.replace_automated_keys(:class_cancel, keys_to_be_replaced)
    end
    if settings["Guardian"] == true
      template_contents[:guardian] = message_template.guardian_template_content.replace_automated_keys(:class_cancel, keys_to_be_replaced)
    end
    if settings["Employee"] == true
      template_contents[:employee] = message_template.employee_template_content.replace_automated_keys(:class_cancel, keys_to_be_replaced)
    end
    return template_contents
  end

  def self.class_cancel_initiation_allowed?(timetable_swap)
    sms_setting = SmsSetting.new()
    if timetable_swap.alert_notify == 1 &&  sms_setting.application_sms_active
      return true
    else
      return false
    end
  end


  #CLASS SWAP----------------------------------------------------------------------------------------------------------

  def self.class_swap(timetable_swap)
    if class_swap_initiation_allowed?(timetable_swap)
      settings = SmsSetting.get_settings_for("TimetableSwapEnabled")
      recipients1 = class_swap1_recipient_builder(timetable_swap, settings)
      template_contents1 = class_swap1_contents_builder(timetable_swap, settings)
      recipients2 = class_swap2_recipient_builder(timetable_swap, settings)
      template_contents2 = class_swap2_contents_builder(timetable_swap, settings)
      SmsManager.send_template_based_messages(template_contents1,recipients1,{},true)
      SmsManager.send_template_based_messages(template_contents2,recipients2,{},true)
    end
  end


  def self.class_swap_key_builder(timetable_swap)
    keys_to_be_replaced = {}
    keys_to_be_replaced[:scheduled_subject] = timetable_swap.email_attributes('subject_name')
    keys_to_be_replaced[:scheduled_date] = timetable_swap.date.to_s
    keys_to_be_replaced[:scheduled_teacher] = timetable_swap.email_attributes('teacher_first_name')
    keys_to_be_replaced[:batch_name] = timetable_swap.email_attributes('batch_name')
    keys_to_be_replaced[:swapped_subject] = timetable_swap.email_attributes('new_subject_name')
    keys_to_be_replaced[:swapped_teacher] = timetable_swap.email_attributes('new_teacher_name')
    keys_to_be_replaced[:class_timing_name_from] = timetable_swap.email_attributes('start_time')
    keys_to_be_replaced[:class_timing_name_to] = timetable_swap.email_attributes('end_time')
    return keys_to_be_replaced
  end

  def self.class_swap1_recipient_builder(timetable_swap, settings)
    is_new_record = (timetable_swap.created_at == timetable_swap.updated_at)
    tte = TimetableEntry.find(timetable_swap.timetable_entry, :include => [{:batch => :students }, :employees])
    students = tte.batch.students
    teachers_list_out = timetable_swap.old_swap_teacher.present? ? timetable_swap.old_swap_teacher.to_a : (tte.employees).dup.flatten
    teachers_list_in = (!timetable_swap.is_cancelled) ? timetable_swap.employee.to_a : []
    teachers_list_out = is_new_record ? teachers_list_out : ((teachers_list_out - teachers_list_in).to_a)
    recipients = {}
    if settings["Student"] == true
      recipients[:student_ids] =  students.collect(&:id)
    end
    if settings["Guardian"] == true
      recipients[:guardian_sids] = students.collect(&:id)
    end
    if timetable_swap.employee_id_changed?
      if settings["Employee"] == true
        recipients[:employee_ids] = teachers_list_out.collect(&:id)
      end
    end
    return recipients
  end

  def self.class_swap1_contents_builder(timetable_swap, settings)
    #continue here
    template_contents={}
    keys_to_be_replaced = class_swap_key_builder(timetable_swap)
    message_template = MessageTemplate.find_by_automated_template_name("class_swap1")
    student_template_content = message_template.student_template_content.replace_automated_keys(:class_swap1, keys_to_be_replaced)
    if  timetable_swap.employee_id_changed?
      employee_template_content = message_template.employee_template_content.replace_automated_keys(:class_swap1, keys_to_be_replaced)
    end
    guardian_template_content = message_template.guardian_template_content.replace_automated_keys(:class_swap1, keys_to_be_replaced)
    template_contents = {:student => student_template_content, :guardian=> guardian_template_content, :employee=>employee_template_content}
    return template_contents
  end


  def self.class_swap2_recipient_builder(timetable_swap, settings)
    is_new_record = (timetable_swap.created_at == timetable_swap.updated_at)
    tte = TimetableEntry.find(timetable_swap.timetable_entry, :include => [{:batch => :students }, :employees])
    students = tte.batch.students
    teachers_list_out = timetable_swap.old_swap_teacher.present? ? timetable_swap.old_swap_teacher.to_a : (tte.employees).dup.flatten
    teachers_list_in = (!timetable_swap.is_cancelled) ? timetable_swap.employee.to_a : []
    teachers_list_out = is_new_record ? teachers_list_out : ((teachers_list_out - teachers_list_in).to_a)
    recipients = {:employee_ids => [] }
    recipients[:employee_ids] = teachers_list_in.collect(&:id) if teachers_list_in.present?
    return recipients
  end

  def self.class_swap2_contents_builder(timetable_swap, settings)
    template_contents={}
    message_template = MessageTemplate.find_by_automated_template_name("class_swap2")
    keys_to_be_replaced = class_swap_key_builder(timetable_swap)
    template_contents[:employee] = message_template.employee_template_content.replace_automated_keys(:class_swap2, keys_to_be_replaced)
    return template_contents
  end

  def self.class_swap_initiation_allowed?(timetable_swap)
    sms_setting = SmsSetting.new()
    if timetable_swap.alert_notify == 1 &&  sms_setting.application_sms_active
      return true
    else
      return false
    end
  end


  #FEE DUE-----------------------------------------------------------------------------------------------------------
  def self.fee_due(students)
    if fee_due_initiation_allowed?
      recipients = fee_due_recipient_builder(students)
      template_contents = fee_due_contents_builder(students)
      SmsManager.send_template_based_messages(template_contents,recipients,{},true)
    end
  end

  def self.fee_due_recipient_builder(students)
    recipients = {:student_ids => [], :guardian_sids => []}
    recipients[:student_ids] =  students.collect(&:id)
    recipients[:guardian_sids] =  students.collect(&:id)
    return recipients
  end

  def self.fee_due_contents_builder(students)
    template_contents={}
    message_template = MessageTemplate.find_by_automated_template_name("fee_due")
    student_template_content = message_template.student_template_content.content
    guardian_template_content = message_template.guardian_template_content.content
    template_contents = {:student => student_template_content, :guardian=> guardian_template_content}
    return template_contents
  end

  def self.fee_due_initiation_allowed?
    sms_setting = SmsSetting.new()
    if sms_setting.application_sms_active
      return true
    else
      return false
    end
  end



  #STUDENT IMMEDIATE CONTACT-------------------------------------------------------------------------------------------
  def self.student_immediate_contact_changed(student)
    if student_immediate_contact_changed_initiation_allowed?(student)
      recipients = student_immediate_contact_changed_recipient_builder(student)
      template_contents = student_immediate_contact_changed_contents_builder(student)
      SmsManager.send_template_based_messages(template_contents,recipients,{},true)
    end

  end

  def self.student_immediate_contact_changed_recipient_builder(student)
    recipients = {:guardian_sids => [] }
    recipients[:guardian_sids] << student.id
    return recipients
  end

  def self.student_immediate_contact_changed_contents_builder(student)
    template_contents={}
    message_template = MessageTemplate.find_by_automated_template_name("student_immediate_contact_changed")
    username = student.immediate_contact.user.username
    password = "#{student.immediate_contact.user.username}123"
    weird_name = student.full_name
    keys_to_be_replaced = {:username=>username, :password=>password, :weird_name=> weird_name}
    guardian_template_content = message_template.guardian_template_content.replace_automated_keys(:student_immediate_contact_changed, keys_to_be_replaced)
    template_contents = {:guardian=> guardian_template_content}
    return template_contents
  end

  def self.student_immediate_contact_changed_initiation_allowed?(student)
    settings = SmsSetting.get_settings_for("StudentAdmissionEnabled")
    if student.changed and student.changed.include? 'immediate_contact_id' and student.immediate_contact.present? and settings["Guardian"] == true
      return true
    else
      return false
    end
  end




  # EVENT ------------------------------------------------------------------------------------------------------
  def self.event(event)
    if event_initiation_allowed?(event)
      settings =  SmsSetting.get_settings_for("NewsEventsEnabled")
      recipients = event_recipient_builder(event, settings)
      template_contents = event_contents_builder(event, settings)
      SmsManager.send_template_based_messages(template_contents,recipients,{},true)
    end
  end


  def self.event_recipient_builder(event, settings)
    sms_setting = SmsSetting.new()
    recipients = {}
    student_ids=[];  guardian_sids=[]; employee_ids=[];
    if event.is_common == true
      users = User.active.find(:all,:include=>[{:student_entry=>:immediate_contact},:employee_entry])
      users.each do |u|
        if u.student == true
          student = u.student_record
          if student.present?
            student_ids << student.id
            guardian_sids << student.id
          end
        elsif u.employee == true
          employee = u.employee_record
          employee_ids << employee.id
        else
        end
      end
    else
      batch_event = BatchEvent.find_all_by_event_id(event.id)
      unless batch_event.empty?
        batch_event.each do |b|
          batch_students = Student.find(:all, :conditions=>["batch_id = ?",b.batch_id],:include=> :immediate_contact)
          batch_students.each do |s|
            student_ids << s.id
            guardian_sids << s.id
          end
        end
      end
      department_event = EmployeeDepartmentEvent.find_all_by_event_id(event.id)
      unless department_event.empty?
        department_event.each do |d|
          dept_emp = Employee.find(:all, :conditions=>["employee_department_id = ?", d.employee_department_id])
          dept_emp.each do |e|
            employee_ids << e.id
          end
        end
      end

    end

    if settings["Student"] == true
      recipients[:student_ids] = student_ids
    end
    if settings["Guardian"] == true
      recipients[:guardian_sids] = guardian_sids
    end
    if settings["Employee"] == true
      recipients[:employee_ids] = employee_ids
    end
    return recipients
  end


  def self.event_contents_builder(event, settings)
    template_contents={}
    message_template = MessageTemplate.find_by_automated_template_name("event")
    start_time = format_date(event.start_date,:format=>:short_date)
    end_time = format_date(event.end_date,:format=>:short_date)
    keys_to_be_replaced = {:event_name=>event.title, :start_time=>start_time, :end_time=> end_time}
    if settings["Student"] == true
      template_contents[:student] = message_template.student_template_content.replace_automated_keys(:event, keys_to_be_replaced)
    end
    if settings["Guardian"] == true
      template_contents[:guardian] = message_template.guardian_template_content.replace_automated_keys(:event, keys_to_be_replaced)
    end
    if settings["Employee"] == true
      template_contents[:employee] = message_template.employee_template_content.replace_automated_keys(:event, keys_to_be_replaced)
    end
    return template_contents
  end


  def self.event_initiation_allowed?(event)
    sms_setting = SmsSetting.new()
    if sms_setting.application_sms_active and event.manual
      return true
    else
      return false
    end
  end

  # GRADEBOOK SCHEDULE EXAMS ------------------------------------------------------------------------------------------------------
  def self.gradebook_schedule_exams(scheduled_exam_details)
    if gradebook_schedule_exams_initiation_allowed?(scheduled_exam_details)
      recipients = gradebook_schedule_exams_recipient_builder(scheduled_exam_details)
      template_contents = gradebook_schedule_exams_contents_builder(scheduled_exam_details)
      SmsManager.send_template_based_messages(template_contents,recipients,{},true)
    end
  end

  def self.gradebook_schedule_exams_recipient_builder(scheduled_exam_details)
    recipients = {:student_ids => [], :guardian_sids => []}
    recipients[:student_ids] =  scheduled_exam_details[:recipients]
    recipients[:guardian_sids] = scheduled_exam_details[:recipients]
    return recipients
  end

  def self.gradebook_schedule_exams_contents_builder(scheduled_exam_details)
    template_contents={}
    message_template = MessageTemplate.find_by_automated_template_name("gradebook_schedule_exams")
    keys_to_be_replaced = {:exam_name=>scheduled_exam_details[:exam_name], :exam_schedule=>scheduled_exam_details[:exam_schedule] }
    student_template_content = message_template.student_template_content.replace_automated_keys(:gradebook_schedule_exams, keys_to_be_replaced)
    guardian_template_content = message_template.guardian_template_content.replace_automated_keys(:gradebook_schedule_exams, keys_to_be_replaced)
    template_contents = {:student => student_template_content, :guardian=> guardian_template_content}
    return template_contents
  end

  def self.gradebook_schedule_exams_initiation_allowed?(scheduled_exam_details)
    sms_setting = SmsSetting.new()
    if sms_setting.application_sms_active
      return true
    else
      return false
    end
  end

  # GRADEBOOK RESULT PUBLISHED ------------------------------------------------------------------------------------------------------
  def self.gradebook_result_published(published_exam_details)
    if gradebook_schedule_exams_initiation_allowed?(published_exam_details)
      recipients = gradebook_result_published_recipient_builder(published_exam_details)
      template_contents = gradebook_result_published_contents_builder(published_exam_details)
      SmsManager.send_template_based_messages(template_contents,recipients,{},true)
    end
  end

  def self.gradebook_result_published_recipient_builder(published_exam_details)
    recipients = {:student_ids => [], :guardian_sids => []}
    recipients[:student_ids] =  published_exam_details[:recipients]
    recipients[:guardian_sids] = published_exam_details[:recipients]
    return recipients
  end

  def self.gradebook_result_published_contents_builder(published_exam_details)
    template_contents={}
    message_template = MessageTemplate.find_by_automated_template_name("gradebook_publish_results")
    keys_to_be_replaced = {:exam_name=>published_exam_details[:exam_name]}
    student_template_content = message_template.student_template_content.replace_automated_keys(:gradebook_publish_results, keys_to_be_replaced)
    guardian_template_content = message_template.guardian_template_content.replace_automated_keys(:gradebook_publish_results, keys_to_be_replaced)
    template_contents = {:student => student_template_content, :guardian=> guardian_template_content}
    template_contents[:type] = :gradebook_publish_results
    template_contents[:automated_params] = {:report_batch_id=>published_exam_details[:report_batch_id]}
    return template_contents
  end

  def self.gradebook_result_published_initiation_allowed?(published_exam_details)
    sms_setting = SmsSetting.new()
    if sms_setting.application_sms_active
      return true
    else
      return false
    end
  end


end
