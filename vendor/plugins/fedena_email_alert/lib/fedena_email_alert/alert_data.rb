
FedenaEmailAlert.make do
  alert(:student_creation,:student,:after_create,nil,nil,nil,nil)do
    to(:recipient=>"student",
      :to=>Proc.new{(is_email_enabled)? user : []},
      :message=>["full_name","user.school_name","admission_no"],
      :subject=>["full_name","user.school_name"],
      :stud_name=>Proc.new{},
      :first_name=>Proc.new{instance_eval("user.first_name")},
      :footer=>["user.school_details"])
  end
  alert(:transfer_batch,:student,:after_update,nil,nil,Proc.new{"mail_value"},Proc.new{batch_id_changed?}) do
    to(:recipient=>"parent",
      :to=>Proc.new{is_email_enabled ? immediate_contact.present? ? immediate_contact.user : [] : []},
      :message=>["immediate_contact.full_name","full_name","admission_no","old_batch","new_batch"],
      :subject=>["full_name","user.school_name"],
      :stud_name=>Proc.new{},
      :footer=>["user.school_details"])


    to(:recipient=>"student",
      :to=>Proc.new{(is_email_enabled)? user : []},

      :message=>["full_name","admission_no","old_batch","new_batch"],
      :subject=>["full_name","user.school_name"],
      :stud_name=>Proc.new{},
      :footer=>["user.school_details"])
  end

  alert(:poll_creation,:poll_member,:after_create,"fedena_poll",nil,nil,nil) do
    to(
      :recipient=>"members",
      :to=>(
        Proc.new do
          if member.is_a?(Batch)
            member.students.all(:conditions=>{:is_email_enabled => true}, :include => :user).collect(&:user)
          elsif member.is_a?(EmployeeDepartment)
            member.employees.all(:include => :user).collect(&:user)
          end
        end
      ),
      :message=>["poll_question.title","poll_question.poll_creator.school_name"],
      :subject=>["poll_question.title","poll_question.poll_creator.school_name"],
      :stud_name=>Proc.new{},
      :footer=>["poll_question.poll_creator.school_details"]

    )
  end
  alert(:parent_creation,:student,:after_update,nil,nil,Proc.new{immediate_contact_id!=nil},Proc.new{immediate_contact_id_changed?}) do
    to(
      :recipient=>"parent",
      :to=>Proc.new{(is_email_enabled? and immediate_contact.email.present?) ? (immediate_contact.user) : []},
      :subject=>["full_name","user.school_name"],
      :message=>["full_name","user.school_name","immediate_contact.user.username"],
      :stud_name=>Proc.new{},
      :footer=>["user.school_details"]
    )
  end

  alert(:examination_schedule_publishing,:exam_group,:after_update,nil,nil,Proc.new{is_published==true},Proc.new{is_published_changed?}) do
    to(
      :recipient=>"student",
      :to=>Proc.new{batch.students.select{|s| (s.is_email_enabled)}.collect(&:user) },

      :stud_name=>Proc.new{},
      :message=>["school_name","name"],
      :subject=>["school_name"],
      :footer=>["school_details"]
    )

    to(
      :recipient=>"parent",
      :to=>Proc.new{batch.students.select{|s| s.is_email_enabled? && s.immediate_contact.present? && s.immediate_contact.email.present? }.collect{|s| s.immediate_contact.user}.compact},

      :stud_name=>Proc.new{student_parent_email},
      :message=>["school_name","name"],
      :subject=>["school_name"],
      :footer=>["school_details"]
    )
  end

  alert(:examination_result_publishing,:exam_group,:after_update,nil,nil,Proc.new{result_published==true},Proc.new{result_published_changed?}) do
    to(
      :recipient=>"student",
      :to=>Proc.new{batch.students.select{|s| (s.is_email_enabled)}.collect(&:user)},

      :stud_name=>Proc.new{},
      :message=>["name","school_name"],
      :subject=>["name"],
      :footer=>["school_details"])

    to(
      :recipient=>"parent",
      :to=>Proc.new{batch.students.select{|s| s.is_email_enabled? && s.immediate_contact.present? && s.immediate_contact.email.present? }.collect{|s| s.immediate_contact.user}.compact},

      :stud_name=>Proc.new{student_parent_email},
      :message=>["school_name","name"],
      :subject=>["name"],
      :footer=>["school_details"])
  end

  alert(:daily_wise_attendance_registration,:attendance,:after_create,nil,Proc.new{validate_email_setting},nil,nil) do
    to(
      :recipient=>"student",
      :to=>Proc.new{student.is_email_enabled? ? student.user : [] },
      :message=>["student.full_name","student.admission_no","reason","month_dates","leave_info", "attendance_label_name"],
      :subject=>["student.full_name","month_dates", "attendance_label_name"],
      :stud_name=>Proc.new{},
      :footer=>["student.user.school_details"]

    )
    to(
      :recipient=>"parent",
      :to=>Proc.new{(student.immediate_contact.present? and student.is_email_enabled?) ? student.immediate_contact.user : []},
      :message=>["student.full_name","student.admission_no","reason","month_dates","leave_info", "attendance_label_name"],
      :subject=>["student.full_name","month_dates", "attendance_label_name"],
      :stud_name=>Proc.new{},
      :footer=>["student.user.school_details"]
    )
  end


  alert(:employee_creation,:user,:after_create,nil,Proc.new{employee==true},nil,nil) do
    to(
      :recipient=>"employee",
      :to=>Proc.new{self},
      :message=>["full_name","school_name","username"],
      :stud_name=>Proc.new{},
      :subject=>["full_name","school_name"],
      :footer=>["school_details"]
    )
  end

  alert(:fee_collection_creation,:finance_fee,:after_create,nil,nil,nil,nil) do
    to(
      :recipient=>"student",
      :to=>Proc.new{student.is_email_enabled? ? student.user : []},
      :stud_name=>Proc.new{},
      :message=>["finance_fee_collection.name","student.full_name","due_date","student.user.school_name","student.user.username","finance_fee_collection.id","student_id"],
      :subject=>["finance_fee_collection.name","student.user.school_name"],
      :footer=>["student.user.school_details"]

    )
    to(
      :recipient=>"parent",
      :to=>Proc.new{(student.immediate_contact.present? and student.is_email_enabled?) ? student.immediate_contact.user : [] },
      :message=>["finance_fee_collection.name","student.full_name","due_date","student.user.school_name","student.immediate_contact.user.username","finance_fee_collection.id","student_id"],
      :subject=>["finance_fee_collection.name","student.user.school_name"],
      :stud_name=>Proc.new{},
      :footer=>["student.user.school_details"]
    )
  end

  alert(:fee_submission,:finance_transaction,:after_create,nil,Proc.new{(["FinanceFee","HostelFee","TransportFee"].include?(finance_type) and payee_type=="Student")},nil,nil) do
    to(
      :recipient=>"student",
      :to=>Proc.new{payee.is_email_enabled? ? payee.user : []},
      :stud_name=>Proc.new{},
      :message=>["currency_name","date_of_transaction","amount.to_f","amount_with_precision","name_of_collection","id","payee.user.username","finance_type","finance_id"],
      :subject=>["currency_name","amount.to_f","amount_with_precision","payee.user.school_name","name_of_collection"],
      :footer=>["payee.user.school_details"]
    )
    to(
      :recipient=>"parent",
      :to=>Proc.new{(payee.immediate_contact.present? and payee.is_email_enabled) ? payee.immediate_contact.user : []},
      :stud_name=>Proc.new{},
      :message=>["currency_name","date_of_transaction","amount.to_f","amount_with_precision","name_of_collection","id","payee.immediate_contact.user.username","finance_type","finance_id"],
      :subject=>["currency_name","amount.to_f","amount_with_precision","payee.user.school_name","name_of_collection"],
      :footer=>["payee.user.school_details"]
    )
  end

  alert(:leave_creation,:apply_leave,:after_create,nil,nil,nil,nil) do
    to(
      :recipient=>"employee",
      :to=>Proc.new{employee.reporting_manager},
      :message=>["employee.full_name","employee.employee_number","leave_days","reason"],
      :subject=>["employee.full_name"],
      :stud_name=>Proc.new{},
      :footer=>["employee.user.school_details"]
    )

  end
  alert(:leave_approval,:apply_leave,:after_update,nil,nil,nil, Proc.new{approved_changed?}) do
    to(
      :recipient=>"employee",
      :to=>Proc.new{employee.user},

      :message=>["reason","leave_days","leave_status"],
      :subject=>["leave_status","leave_days"],
      :stud_name=>Proc.new{},
      :footer=>["employee.user.school_details"]
    )
  end

  alert(:common_event_creation,:event,:after_create,nil,Proc.new{is_common==true and is_exam==false},nil,nil) do
    to(
      :recipient=>"members",
      :to=> :all_users,
      :message=>["title","event_days"],
      :stud_name=>Proc.new{},
      :subject=>["title","school_name","event_days"],
      :footer=>["school_details"]
    )

  end

  alert(:event_creation_for_batch,:batch_event,:after_create,nil,Proc.new{event.is_exam==false and event.is_due==false},nil,nil) do
    to(
      :recipient=>"student",
      :to=>Proc.new{batch.students.select{|s| (s.is_email_enabled)}.collect(&:user)},
      :message=>["event.title","event.event_days"],
      :stud_name=>Proc.new{},
      :subject=>["event.title","event.school_name","event.event_days"],
      :footer=>["event.school_details"]
    )
    to(
      :recipient=>"parent",
      :to=>Proc.new{batch.students.select{|s| s.is_email_enabled? && s.immediate_contact.present? && s.immediate_contact.email.present? }.collect{|s| s.immediate_contact.user}.compact},
      :message=>["event.title","event.event_days"],
      :stud_name=>Proc.new{},
      :subject=>["event.title","event.school_name","event.event_days"],
      :footer=>["event.school_details"]
    )
  end

  alert(:event_creation_for_employee,:employee_department_event,:after_create,nil,nil,nil,nil) do
    to(
      :recipient=>"employee",
      :to=>Proc.new{employee_department.employees.collect(&:user).compact},
      :message=>["event.title","event.event_days"],
      :subject=>["event.title","event.school_name","event.event_days"],
      :stud_name=>Proc.new{},
      :footer=>["event.school_details"]

    )

  end

  alert(:subject_wise_attendance_registration,:subject_leave,:after_create,nil,Proc.new{validate_email_setting},nil,nil) do
    to(
      :recipient=>"student",
      :to=>Proc.new{(student.is_email_enabled? && student.email.present?) ? [student.user] : []},
      :message=>["student.full_name","student.admission_no","reason","subject.name","class_timing.name", "attendance_label_name"],
      :subject=>["student.full_name","month_date", "attendance_label_name"],
      :stud_name=>Proc.new{},
      :footer=>["student.user.school_details"]
    )
    to(
      :recipient=>"parent",
      :to=>Proc.new{(student.is_email_enabled? && student.immediate_contact.present? && student.immediate_contact.email.present?) ? [student.immediate_contact.user] : []},
      :message=>["student.full_name","student.admission_no","reason","subject.name","class_timing.name", "attendance_label_name"],
      :subject=>["student.full_name","month_date","attendance_label_name"],
      :stud_name=>Proc.new{},
      :footer=>["student.user.school_details"]

    )
  end

  alert(:timetable_swap_email,:timetable_swap,:after_create,nil,Proc.new{is_cancelled == false and alert_notify == 1},nil,nil) do
    to(
      :recipient=>"student",
      :to=>Proc.new{timetable_entry.batch.students.select{|s| s.is_email_enabled?}.collect(&:user).compact},
      :message=>["subject_name","date","start_time","end_time","old_teacher_name","batch_name","new_subject_name","fedena_instance_url","new_teacher_name"],      
      :subject=>["subject_name","date","new_subject_name"],
      :stud_name=>Proc.new{},
      :footer=>[]
    )
    to(
      :recipient=>"parent",
      :to=>Proc.new{timetable_entry.batch.students.all(:include => {:immediate_contact => :user}) \
                        .select{|s| s.is_email_enabled? && s.immediate_contact.present? && s.immediate_contact.email.present? } \
                        .collect{|s| s.immediate_contact.user}.compact},
      :message=>["subject_name","date","start_time","end_time","old_teacher_name","batch_name","new_subject_name","fedena_instance_url","new_teacher_name"],      
      :subject=>["subject_name","date","new_subject_name"],
      :stud_name=>Proc.new{},
      :footer=>[]

    )
    to(
      :recipient=>"employee",
      :to=>(
        Proc.new do
          employees = []
          employees += timetable_entry.employees
          employees << employee
          employees.compact.collect(&:user).compact
        end
        ),
      :message=>["subject_name","old_teacher_name","batch_name","date","start_time","end_time","new_subject_name","new_teacher_name","fedena_instance_url"],
      :subject=>["subject_name","date","new_subject_name"],
      :stud_name=>Proc.new{},
      :footer=>[]

    )
  end
  
  alert(:timetable_cancel_email,:timetable_swap,:after_create,nil,Proc.new{is_cancelled == true and alert_notify == 1},nil,nil) do
    to(
      :recipient=>"student",
      :to=>Proc.new{timetable_entry.batch.students.select{|s| s.is_email_enabled?}.collect(&:user).compact},
      :message=>["subject_name","old_teacher_name","batch_name","date","start_time","end_time","fedena_instance_url"],
      :subject=>["subject_name","date"],
      :stud_name=>Proc.new{},
      :footer=>[]
    )
    to(
      :recipient=>"parent",
      :to=>Proc.new{timetable_entry.batch.students.all(:include => {:immediate_contact => :user}) \
                        .select{|s| s.is_email_enabled? && s.immediate_contact.present? && s.immediate_contact.email.present? } \
                        .collect{|s| s.immediate_contact.user}.compact},
      :message=>["subject_name","old_teacher_name","batch_name","date","start_time","end_time","fedena_instance_url"],
      :subject=>["subject_name","date"],
      :stud_name=>Proc.new{},
      :footer=>[]

    )
    to(
      :recipient=>"employee",
      :to=>(
        Proc.new do
          employees = []
          employees += timetable_entry.employees
          employees.compact.collect(&:user).compact
        end
      ),
      :message=>["subject_name","old_teacher_name","batch_name","date","start_time","end_time","fedena_instance_url"],
      :subject=>["subject_name","date"],
      :stud_name=>Proc.new{},
      :footer=>[]

    )
  end
  
  alert(:timetable_swap_email_update,:timetable_swap,:after_update,nil,Proc.new{is_cancelled == false and alert_notify == 1},Proc.new{"mail_value"},Proc.new{subject_id_changed? || employee_id_changed?}) do
    to(
      :recipient=>"student",
      :to=>Proc.new{timetable_entry.batch.students.select{|s| s.is_email_enabled?}.collect(&:user).compact},
      :message=>["subject_name","date","start_time","end_time","old_teacher_name","batch_name","new_subject_name","fedena_instance_url","new_teacher_name"],      
      :subject=>["subject_name","date","new_subject_name"],
      :stud_name=>Proc.new{},
      :footer=>[]
    )
    to(
      :recipient=>"parent",
      :to=>Proc.new{timetable_entry.batch.students.all(:include => {:immediate_contact => :user}) \
                        .select{|s| s.is_email_enabled? && s.immediate_contact.present? && s.immediate_contact.email.present? } \
                        .collect{|s| s.immediate_contact.user}.compact},
      :message=>["subject_name","date","start_time","end_time","old_teacher_name","batch_name","new_subject_name","fedena_instance_url","new_teacher_name"],      
      :subject=>["subject_name","date","new_subject_name"],
      :stud_name=>Proc.new{},
      :footer=>[]

    )
    to(
      :recipient=>"employee",
      :to=>(
      Proc.new do
        employees = []
        employees << employee
        employees << old_swap_teacher if old_swap_teacher.present?
        employees.compact.collect(&:user).compact
      end
      ),
      :message=>["subject_name","old_teacher_name","batch_name","date","start_time","end_time","new_subject_name","new_teacher_name","fedena_instance_url"],
      :subject=>["subject_name","date","new_subject_name"],
      :stud_name=>Proc.new{},
      :footer=>[]

    )
  end
  
end
