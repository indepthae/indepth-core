class LeaveGroupEmployee < ActiveRecord::Base
  attr_accessor :selected, :name, :department, :position, :grade
  
  belongs_to :employee, :polymorphic => true
  belongs_to :leave_group
  
  validates_presence_of :employee_id
  
  
  def self.leave_group_employees(leave_type)
    LeaveGroupEmployee.all(:select => "employees.* ,leave_group_employees.employee_id",
                           :joins => "inner join leave_groups on leave_groups.id = leave_group_employees.leave_group_id 
                           inner join leave_group_leave_types on leave_groups.id = leave_group_leave_types.leave_group_id 
                           inner join employees on employees.id = leave_group_employees.employee_id", 
                           :conditions => ["employee_leave_type_id = ? " , leave_type.id])
  end
  
end
