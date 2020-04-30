class ArchivedEmployeeSalaryStructureComponent < ActiveRecord::Base
  xss_terminate
  
  belongs_to :payroll_category
  belongs_to :archived_employee_salary_structure
  validates_presence_of :amount, :payroll_category_id
  validates_numericality_of :amount, :greater_than_or_equal_to => 0
end