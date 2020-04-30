[
  {"config_key" => "InstitutionName"                 ,"config_value" => "" },
  {"config_key" => "InstitutionAddress"              ,"config_value" => ""},
  {"config_key" => "InstitutionPhoneNo"              ,"config_value" => ""},
  {"config_key" => "StudentAttendanceType"           ,"config_value" => "Daily"},
  {"config_key" => "CurrencyType"                    ,"config_value" => "$"},
  {"config_key" => "Locale"                          ,"config_value" => "en"},
  {"config_key" => "AdmissionNumberAutoIncrement"    ,"config_value" => "1"},
  {"config_key" => "EmployeeNumberAutoIncrement"     ,"config_value" => "1"},
  {"config_key" => "TotalSmsCount"                   ,"config_value" => "0"},
  {"config_key" => "FinancialYearStartDate"          ,"config_value" => Date.today},
  {"config_key" => "FinancialYearEndDate"            ,"config_value" => Date.today+1.year},
  {"config_key" => "AutomaticLeaveReset"             ,"config_value" => "0"},
  {"config_key" => "LeaveResetPeriod"                ,"config_value" => "4"},
  {"config_key" => "LastAutoLeaveReset"              ,"config_value" => nil},
  {"config_key" => "GPA"                             ,"config_value" => "0"},
  {"config_key" => "CWA"                             ,"config_value" => "0"},
  {"config_key" => "CCE"                             ,"config_value" => "0"},
  {"config_key" => "DefaultCountry"                  ,"config_value" => Country.find_by_name('India')? "#{Country.find_by_name('India').id}" : "76"},
  {"config_key" => "FirstTimeLoginEnable"            ,"config_value" => "0"},
  {"config_key" => "FeeReceiptNo"                    ,"config_value" => nil},
  {"config_key" => "PrecisionCount"                  ,"config_value" => "2"},
  {"config_key" => "StudentSortMethod"               ,"config_value" => "first_name"},
#  {"config_key" => "SchoolDiscountMarker"            ,"config_value" => "NEW_DISCOUNT_MODE"}
].each do |param|
  Configuration.find_or_create_by_config_key(param)
end

[
  {"config_key" => "AvailableModules"                ,"config_value" => "HR"},
  {"config_key" => "AvailableModules"                ,"config_value" => "Finance"}
].each do |param|
  Configuration.find_or_create_by_config_key_and_config_value(param)
end

if GradingLevel.count == 0
  [
    {"name" => "A"   ,"min_score" => 90 },
    {"name" => "B"   ,"min_score" => 80},
    {"name" => "C"   ,"min_score" => 70},
    {"name" => "D"   ,"min_score" => 60},
    {"name" => "E"   ,"min_score" => 50},
    {"name" => "F"   ,"min_score" => 0}
  ].each do |param|
    GradingLevel.create(param)
  end
end


if User.first( :conditions=>{:admin=>true}).blank?

  employee_category = EmployeeCategory.find_or_create_by_prefix(:name => 'System Admin',:prefix => 'Admin',:status => true)

  employee_position = EmployeePosition.find_or_create_by_name(:name => 'System Admin',:employee_category_id => employee_category.id,:status => true)

  employee_department = EmployeeDepartment.find_or_create_by_code(:code => 'Admin',:name => 'System Admin',:status => true)

  employee_grade = EmployeeGrade.find_or_create_by_name(:name => 'System Admin',:priority => 0 ,:status => true,:max_hours_day=>nil,:max_hours_week=>nil)

  employee = Employee.find_or_create_by_employee_number(:employee_number => 'admin',:joining_date => Date.today,:first_name => 'Admin',:last_name => 'User',
    :employee_department_id => employee_department.id,:employee_grade_id => employee_grade.id,:employee_position_id => employee_position.id,:employee_category_id => employee_category.id,:status => true,:nationality_id =>'76', :date_of_birth => Date.today-365, :email => 'noreply@fedena.com',:gender=> 'm')

  employee.user.update_attributes(:admin=>true,:employee=>false)

end

[
  {"name" => 'Salary'         ,"description" => ' ',"is_income" => false },
  {"name" => 'Donation'       ,"description" => ' ',"is_income" => true},
  {"name" => 'Fee'            ,"description" => ' ',"is_income" => true},
  {"name" => 'Refund'         ,"description" => ' ',"is_income" => false}
].each do |param|
  FinanceTransactionCategory.find_or_create_by_name(param)
end


unless Configuration.find_by_config_key("SetupAttendance").try(:config_value) == "1"
  SetupAttendance.setup_weekdays
  SetupAttendance.setup_class_timings
  SetupAttendance.setup_timetable
  Configuration.create(:config_key => "SetupAttendance",:config_value => "1")
end
