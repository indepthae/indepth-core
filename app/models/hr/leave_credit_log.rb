class LeaveCreditLog < ActiveRecord::Base
  belongs_to :leave_credit
   serialize :reason, Array
  
end
