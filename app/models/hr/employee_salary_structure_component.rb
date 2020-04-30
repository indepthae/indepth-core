class EmployeeSalaryStructureComponent < ActiveRecord::Base
  xss_terminate
  attr_accessor :pc_name
  
  attr_accessor :cat_changed, :destroyed, :cat_name
  belongs_to :payroll_category
  belongs_to :employee_salary_structure
  validates_presence_of :amount, :payroll_category_id
  validates_numericality_of :amount, :greater_than_or_equal_to => 0

  named_scope :load_payroll_category, {:include => :payroll_category}
end