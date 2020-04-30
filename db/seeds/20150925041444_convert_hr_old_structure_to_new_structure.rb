FeatureLock.run_with_feature_lock :hr_enhancement do
  HrSeeds.update_payroll_categories
  HrSeeds.add_payroll_groups
  HrSeeds.update_employee_salary_structure
  HrSeeds.update_archived_employee_salary_structure
  HrSeeds.add_employee_payslips
end
