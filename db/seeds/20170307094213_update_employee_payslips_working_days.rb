working_days = SalaryWorkingDay::DEFAULT_VALUES
(1..5).each do |period|
  sql = "UPDATE employee_payslips INNER JOIN `payslips_date_ranges` ON `payslips_date_ranges`.id = `employee_payslips`.payslips_date_range_id INNER JOIN `payroll_groups` ON `payroll_groups`.id = `payslips_date_ranges`.payroll_group_id SET working_days = #{working_days[period.to_i]||1} WHERE (working_days is null AND payroll_groups.payment_period = #{period})"
  ActiveRecord::Base.connection.execute(sql)
end