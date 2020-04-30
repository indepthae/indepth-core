authorization do
  role :tokens do
    has_permission_on :oauth_user_tokens, :to=>[:index,:revoke]
  end
  
  role :oauth2_manage do
    has_permission_on :oauth_clients, :to=>[:index,:new,:create,:show,:edit,:update,:destroy]
  end

  role :admin do
    includes :oauth2_manage
    includes :tokens
    includes :basic
    includes :payroll_and_payslip
    includes :manage_student_documents
    includes :manage_student_document_categories
    has_permission_on :api_attendances, :to => [:index,:new,:create,:edit,:update,:show,:destroy]
    has_permission_on :api_batches, :to => [:index,:create,:update,:destroy]
    has_permission_on :api_biometric_informations, :to => [:show]
    has_permission_on :api_courses, :to => [:index,:create,:update,:destroy]
    has_permission_on :api_employee_attendances, :to => [:index,:create,:update,:destroy]
    has_permission_on :api_employee_categories, :to => [:index]
    has_permission_on :api_employee_departments, :to => [:index]
    has_permission_on :api_employee_grades, :to => [:index]
    has_permission_on :api_employee_positions, :to => [:index]
    has_permission_on :api_employee_leave_types, :to => [:index]
    has_permission_on :api_leave_groups, :to => [:index, :show]
    has_permission_on :api_employees, :to => [:index,:show,:employee_structure,:create,:upload_photo,:destroy,:biometric]
    has_permission_on :api_exam_groups, :to => [:index,:create]
    has_permission_on :api_exam_scores, :to => [:index,:create,:update]
    has_permission_on :api_grading_levels, :to => [:index]
    has_permission_on :api_news, :to => [:index]
    has_permission_on :api_schools, :to => [:index]
    has_permission_on :api_student_categories, :to => [:index]
    has_permission_on :api_students, :to => [:index,:show,:fee_dues,:student_structure,:create,:upload_photo,:destroy,:exam_report_profile,:attendance_profile,:fee_dues_profile,:biometric,:pay_fees]
    has_permission_on :api_subjects, :to => [:index,:new,:create,:edit,:update,:destroy,:show]
    has_permission_on :api_timetables, :to => [:index]
    has_permission_on :api_finance_transactions, :to => [:index]
    has_permission_on :api_reminders, :to => [:index,:create]
    has_permission_on :api_routes, :to => [:index,:students_route,:employees_route]
    has_permission_on :api_vehicles, :to => [:index,:route_vehicles,:student_vehicle,:employee_vehicle]
  end
  
  role :employee do
    includes :tokens
    includes :basic
    has_permission_on :api_attendances, :to => [:index,:new,:create,:edit,:update,:show,:destroy]
    has_permission_on :api_biometric_informations, :to => [:show]
    has_permission_on :api_employees, :to => [:show,:biometric]
    has_permission_on :api_news, :to => [:index]
    has_permission_on :api_reminders, :to => [:create]
    has_permission_on :api_books, :to => [:index]
    has_permission_on :api_routes, :to => [:index,:employees_route]
    has_permission_on :api_vehicles, :to => [:index,:route_vehicles,:employee_vehicle,:pay_fees]
    has_permission_on :api_payroll, :to => [:show] do
      if_attribute :id => is {user.id}
    end
    has_permission_on :api_students, :to => [:exam_report_profile] do
      if_attribute :has_required_control? => is {true}
    end
  end

  role :student do
    includes :basic
    includes :tokens
    has_permission_on :api_biometric_informations, :to => [:show]
    has_permission_on :api_news, :to => [:index]
    has_permission_on :api_books, :to => [:index]
    has_permission_on :api_students, :to => [:show,:fee_dues_profile,:exam_report_profile,:attendance_profile,:biometric,:pay_fees]
    has_permission_on :api_routes, :to => [:index,:students_route]
    has_permission_on :api_vehicles, :to => [:index,:route_vehicles,:student_vehicle]
  end

  role :parent do
    includes :basic
    includes :tokens
    has_permission_on :api_biometric_informations, :to => [:show]
    has_permission_on :api_news, :to => [:index]
    has_permission_on :api_routes, :to => [:index,:students_route,:fee_dues_profile]
    has_permission_on :api_students, :to => [:show,:biometric,:pay_fees]
    has_permission_on :api_vehicles, :to => [:index,:route_vehicles,:student_vehicle]
  end

  role :basic do
    has_permission_on :api_events, :to => [:index]
    has_permission_on :api_reminders, :to => [:index]
    has_permission_on :api_timetables, :to => [:show]
  end

  role :student_attendance_register do
    has_permission_on :api_attendances, :to => [:index,:new,:create,:edit,:update,:show,:destroy]
  end

  role :subject_attendance do
    has_permission_on :api_attendances, :to => [:index,:new,:create,:edit,:update,:show,:destroy]
  end

  role :manage_course_batch do
    has_permission_on :api_batches, :to => [:index,:create,:update,:destroy]
    has_permission_on :api_biometric_informations, :to => [:show]
    has_permission_on :api_courses, :to => [:index,:create,:update,:destroy]
    has_permission_on :api_students, :to => [:show]
    has_permission_on :api_subjects, :to => [:index,:new,:create,:edit,:update,:destroy,:show]
  end

  role :hr_settings do
    includes :employee_search
    has_permission_on :api_employee_categories, :to => [:index]
    has_permission_on :api_employee_departments, :to => [:index]
    has_permission_on :api_employee_grades, :to => [:index]
    has_permission_on :api_employee_positions, :to => [:index]
    has_permission_on :api_finance_transactions, :to => [:index]
    has_permission_on :api_employee_leave_types, :to => [:index]
    has_permission_on :api_leave_groups, :to => [:index, :show]
  end

  role :manage_employee do
    includes :employee_search
    has_permission_on :api_employees, :to => [:employee_structure,:create,:upload_photo]
    has_permission_on :api_payroll, :to => [:show]
  end
  
  role :employee_search do
    has_permission_on :api_biometric_informations, :to => [:show]
    has_permission_on :api_employees, :to => [:index,:show,:biometric]
  end

  role :payroll_and_payslip do
    includes :employee_search
    has_permission_on :api_payroll, :to => [:show]
    has_permission_on :api_payroll_groups, :to => [:index]
  end

  role :approve_reject_payslip do
    has_permission_on :api_payroll, :to => [:show]
    has_permission_on :api_payroll_groups, :to => [:index]
  end
  
  role :admission do
    includes :manage_student_documents
    has_permission_on :api_biometric_informations, :to => [:show]
    has_permission_on :api_students, :to => [:show,:create,:upload_photo]
  end
  
  role :students_control do
    includes :manage_student_documents
    includes :manage_student_document_categories
    has_permission_on :api_biometric_informations, :to => [:show]
    has_permission_on :api_students, :to => [:index,:show,:student_structure,:destroy,:biometric]
  end
  
  role :students_view do
    has_permission_on :api_biometric_informations, :to => [:show]
    has_permission_on :api_students, :to => [:show]
  end

  role :employee_attendance do
    has_permission_on :api_employee_attendances, :to => [:index,:create,:update,:destroy]
    has_permission_on :api_employee_leave_types, :to => [:index]
    has_permission_on :api_leave_groups, :to => [:index, :show]
    has_permission_on :api_employees, :to => [:index]
  end

  role :examination_control do
    has_permission_on :api_exam_groups, :to => [:index,:create]
    has_permission_on :api_exam_scores, :to => [:index,:create,:update]
    has_permission_on :api_grading_levels, :to => [:index]
    has_permission_on :api_students, :to => [:index,:exam_report_profile]
  end
  
  role :enter_results do
    has_permission_on :api_exam_groups, :to => [:index]
    has_permission_on :api_exam_scores, :to => [:index,:create,:update]
  end
  
  role :subject_exam do
    has_permission_on :api_exam_groups, :to => [:index]
    has_permission_on :api_exam_scores, :to => [:index]
  end

  role :manage_news do
    has_permission_on :api_news, :to => [:index]
  end

  role :finance_control do
    has_permission_on :api_payroll_groups, :to => [:index]
    has_permission_on :api_finance_transactions, :to => [:index]
    has_permission_on :api_students, :to => [:fee_dues]
  end

  role :general_settings do
    has_permission_on :api_schools, :to => [:index]
    has_permission_on :api_student_categories, :to => [:index]
  end

  role :subject_master do
    has_permission_on :api_subjects, :to => [:index,:new,:create,:edit,:update,:destroy,:show]
  end

  role :manage_timetable do
    has_permission_on :api_timetables, :to => [:index]
  end

  role :timetable_view do
    has_permission_on :api_timetables, :to => [:index]
  end

  role :hostel_admin do
    has_permission_on :api_hostels, :to => [:index]
  end

  role :transport_admin do
    has_permission_on :api_vehicles, :to => [:vehicle_details,:student_vehicle,:employee_vehicle]
    has_permission_on :api_routes, :to => [:students_route,:employees_route]
    has_permission_on :api_transports, :to => [:students,:vehicle_members]
  end

  role :librarian do
    has_permission_on :api_books, :to => [:index]
  end
  
  role :manage_student_documents do
    has_permission_on :api_student_documents, :to => [:documents,:create,:destroy,:edit]
  end
  role :manage_student_document_categories do
    has_permission_on :api_student_document_categories, :to => [:index, :create, :edit]
  end
end