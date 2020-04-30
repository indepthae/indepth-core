class EmployeeOvertime < ActiveRecord::Base
  xss_terminate
  
  has_one :hr_formula, :as => :formula, :dependent => :destroy
  belongs_to :payroll_group

  accepts_nested_attributes_for :hr_formula
end