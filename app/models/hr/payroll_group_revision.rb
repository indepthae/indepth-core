class PayrollGroupRevision < ActiveRecord::Base
  xss_terminate
  
  belongs_to :payroll_group
  serialize :categories
end
