module LeaveGroupHelper
  
 def leave_credit_type(id) 
   leave_type = EmployeeLeaveType.find(id)
   return  leave_type.credit_type
   
 end
  
end