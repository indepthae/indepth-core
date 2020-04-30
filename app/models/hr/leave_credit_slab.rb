class LeaveCreditSlab < ActiveRecord::Base
  belongs_to :employee_leave_type
  
  validates_numericality_of :leave_count, :greater_than_or_equal_to => 0
  
end
