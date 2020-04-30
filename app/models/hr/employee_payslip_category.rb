class EmployeePayslipCategory < ActiveRecord::Base
  xss_terminate
  attr_accessor :pc_name, :is_deduction, :pc_code

  belongs_to :employee_payslip
  belongs_to :payroll_category

  validates_numericality_of :amount, :greater_than_or_equal_to => 0

  before_save :verify_precision

  def verify_precision
    self.amount = FedenaPrecision.set_and_modify_precision amount
  end

end