class PayslipAdditionalLeave < ActiveRecord::Base
  xss_terminate
  
  belongs_to :employee_payslip
  belongs_to :employee_additional_leave
end
