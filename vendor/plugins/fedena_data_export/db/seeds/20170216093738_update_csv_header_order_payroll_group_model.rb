payroll_group_model = ExportStructure.find_by_model_name('payroll_group')
unless payroll_group_model.nil?
  payroll_group_model.csv_header_order = ["name", "salary_type", "payment_period", "generation_day", "payroll_categories", "enable_lop", "employee_lop_formula", "lop_calculation_method", "lop_prorated_formulas"]
  payroll_group_model.save
end