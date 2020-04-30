
cat_link = MenuLink.find_by_name("create_payslip")
unless cat_link.nil?
  cat_link.name = 'payroll_and_payslips'
  cat_link.target_controller = 'employee'
  cat_link.target_action = 'payroll_and_payslips'
  cat_link.save
end
