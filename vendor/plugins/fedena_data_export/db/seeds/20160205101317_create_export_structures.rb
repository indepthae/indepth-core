[
  {"query"=>{"find_in_batches"=>{:batch_size=>10, :conditions=>{},:include => [:employee,:employee_leave_type]}}, "plugin_name"=>nil, "model_name"=>"employee_attendance", "template"=>"/api/employee_attendances/attendances.xml.erb","csv_header_order" => ["attendance_date","employee_number","leave_type","reason","half_day"]},
  {"query"=>{"find_in_batches"=>{:batch_size=>10, :conditions=>{}}}, "plugin_name"=>nil, "model_name"=>"course", "template"=>"/api/courses/courses.xml.erb","csv_header_order" => ["course_name","course_code","section_name","grading_type"]},
  {"query"=>{"find_in_batches"=>{:batch_size=>10, :conditions=>{},:include => [:course]}}, "plugin_name"=>nil, "model_name"=>"batch", "template"=>"/api/batches/batches.xml.erb","csv_header_order" => ["name","course_code","start_date","end_date"]},
  {"query"=>{"find_in_batches"=>{:batch_size=>10, :conditions=>{}}}, "plugin_name"=>nil, "model_name"=>"employee_department", "template"=>"/api/employee_departments/employee_departments.xml.erb","csv_header_order" => ["name","code"]},
  {"query"=>{"find_in_batches"=>{:batch_size=>10, :conditions=>{}}}, "plugin_name"=>nil, "model_name"=>"employee_grade", "template"=>"/api/employee_grades/employee_grades.xml.erb","csv_header_order" => ["name","priority","max_hours_day","max_hours_week"]},
  {"query"=>{"find_in_batches"=>{:batch_size=>10, :conditions=>{}}}, "plugin_name"=>nil, "model_name"=>"employee_category", "template"=>"/api/employee_categories/employee_categories.xml.erb","csv_header_order" => ["name","prefix"]},
  {"query"=>{"find_in_batches"=>{:batch_size=>10, :conditions=>{}, :include=>[:payroll_categories, {:employee_lop=>{:hr_formula=>:formula_and_conditions}}, {:employee_overtime=>{:hr_formula=>:formula_and_conditions}}]}}, "plugin_name"=>nil, "model_name" => "payroll_group", "template" => "/api/payroll_groups/payroll_groups.xml.erb", "csv_header_order" => ["name", "salary_type", "payment_period", "generation_day", "employee_lop_formula", "employee_overtime_formula", "enable_lop", "payroll_categories"]},
  {"query"=>{"find_in_batches"=>{:batch_size=>10, :conditions=>{},:include => [:batch]}}, "plugin_name"=>nil, "model_name"=>"attendance", "template"=>"/api/attendances/attendances.xml.erb","csv_header_order" => ["student_admission_no","roll_number","forenoon","afternoon","date","batch_name","reason"]},
  {"query"=>{"find_in_batches"=>{:batch_size=>10, :conditions=>{},:include => [:master_transaction,:payee]}}, "plugin_name"=>nil, "model_name"=>"finance_transaction", "template"=>"/api/finance_transactions/finance_transactions.xml.erb","csv_header_order" => ["title","description","amount","fine_included","transaction_date","fine_amount","master_transaction","finance","payee","receipt_no","voucher_no"]},
  {"query"=>{"find_in_batches"=>{:batch_size=>10, :conditions=>{},:include => [:batch]}}, "plugin_name"=>nil, "model_name"=>"subject", "template"=>"/api/subjects/subjects.xml.erb","csv_header_order" => ["name","code","batch","no_exams","max_weekly_classes","credit_hours","elective_group","assigned_students"]},
  {"query"=>{"find_in_batches"=>{:batch_size=>10, :conditions=>{}}}, "plugin_name"=>nil, "model_name"=>"employee_leave_type", "template"=>"/api/employee_leave_types/employee_leave_types.xml.erb","csv_header_order" => ["name", "code", "is_active", "max_leave_count", "carry_forward", "lop_enabled", "max_carry_forward_leaves", "carry_forward_type", "reset_date", "creation_status"]},
  {"query"=>{"find_in_batches"=>{:batch_size=>10, :conditions=>{},:include => [:exams,:batch,:cce_exam_category]}}, "plugin_name"=>nil, "model_name"=>"exam_group", "template"=>"/api/exam_groups/exam_groups.xml.erb","csv_header_order" => ["name","batch","exam_type","is_published","result_published","exam_date","cce_exam_category","exam_detail"]},
  {"query"=>{"find_in_batches"=>{:batch_size=>10, :conditions=>{},:include => [:timetable,:batch,:class_timing,:employee]}}, "plugin_name"=>nil, "model_name"=>"timetable_entry", "template"=>"/api/timetables/timetable_entries.xml.erb","csv_header_order" => ["timetable","weekday","batch","class_timing","employee"]},
  {"query"=>{"find_in_batches"=>{:batch_size=>10, :conditions=>{},:include => [:employee_category]}}, "plugin_name"=>nil, "model_name"=>"employee_position", "template"=>"/api/employee_positions/employee_positions.xml.erb","csv_header_order" => ["name","employee_category"]},
  {"query"=>{"find_in_batches"=>{:batch_size=>10, :conditions=>{},:include => [:student,:exam,:grading_level]}}, "plugin_name"=>nil, "model_name"=>"exam_score", "template"=>"/api/exam_scores/exam_scores.xml.erb","csv_header_order" => ["student","roll_number","exam_group","batch","subject","marks","grading_level","remarks"]},
  {"query"=>{"find_in_batches"=>{:batch_size=>10, :conditions=>{}}}, "plugin_name"=>nil, "model_name"=>"configuration", "template"=>"/api/schools/school_detail.xml.erb","csv_header_order" => ["institute_name","institute_address","institute_phone","institute_language","institute_currency","institute_time_zone","image"]},
  {"query"=>{"find_in_batches"=>{:batch_size=>10, :conditions=>{},:include => [:employee_category, :employee_position, :employee_grade, :employee_department, :reporting_manager, :nationality, :home_country, :office_country, :employee_additional_details, :employee_bank_details, {:employee_salary_structure => [{:employee_salary_structure_components => :payroll_category}, :payroll_group]}]}}, "plugin_name"=>nil, "model_name"=>"employee", "template"=>"/api/employees/employee_exports.xml.erb","csv_header_order" => ["employee_number","employee_name","joining_date","employee_department","employee_category","employee_position","employee_grade","job_title","reporting_manager","gender","email","status","qualification","total_experiance","experiance_info","date_of_birth","marital_status","children_count","father_name","mother_name","spouse_name","blood_group","nationality","home_address","city","state","country","pin_code","office_address","office_city","office_country","office_pin_code","office_phone1","office_phone2","mobile","home_phone","fax","biometric_id","employee_additional_details","employee_bank_details","employee_salary_details"]},
  {"query"=>{"find_in_batches"=>{:batch_size=>10, :conditions=>{},:include => [:batch,:nationality,:student_category,:country,:immediate_contact,:student_additional_details]}}, "plugin_name"=>nil, "model_name"=>"student", "template"=>"/api/students/student_exports.xml.erb","csv_header_order" => ["admission_no","roll_number","student_name","batch_name","admission_date","date_of_birth","blood_group","gender","nationality","language","category","religion","address","city","state","pin_code","country","birth_place","phone","mobile","email","immediate_contact","biometric_id","all_siblings","is_sms_enabled","is_email_enabled","student_additional_details"]},
  {"query"=>{"find_in_batches"=>{:batch_size=>10, :conditions=>{}}}, "plugin_name"=>"fedena_library", "model_name"=>"book", "template"=>"/api/books/books.xml.erb","csv_header_order" => ["title","author","book_number","status"]},
  {"query"=>{"find_in_batches"=>{:batch_size=>10, :conditions=>{},:include => [:wardens]}}, "plugin_name"=>"fedena_hostel", "model_name"=>"hostel", "template"=>"/api/hostels/hostels.xml.erb","csv_header_order" => ["name","hostel_type","other_info","wardens"]},
  {"query"=>{"find_in_batches"=>{:batch_size=>10, :conditions=>{},:include => [:main_route,:transports]}}, "plugin_name"=>"fedena_transport", "model_name"=>"vehicle", "template"=>"/api/vehicles/vehicles.xml.erb","csv_header_order" => ["name","main_route","no_of_seats","status","passengers"]}
].each do |param|
  export_structure = ExportStructure.find_or_initialize_by_model_name(param["model_name"])
  export_structure.update_attributes(param)
end
