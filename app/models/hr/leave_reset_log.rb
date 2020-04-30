class LeaveResetLog < ActiveRecord::Base
  xss_terminate
  
  belongs_to :employee
  serialize :reason, Array
end