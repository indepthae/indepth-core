class PayrollRevision < ActiveRecord::Base
 serialize :payroll_details
 
 has_many :employee_payslips 
 belongs_to :employee_salary_structure
end
