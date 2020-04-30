class PayrollGroupsPayrollCategory < ActiveRecord::Base
  xss_terminate
  
  belongs_to :payroll_category
  belongs_to :payroll_group
  validates_presence_of :payroll_category_id, :sort_order
end