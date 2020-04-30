class LeaveGroupLeaveType < ActiveRecord::Base
  attr_accessor :selected, :type_name, :update_group, :slab_leave_count
  
  belongs_to :employee_leave_type
  belongs_to :leave_group
  
  validates_presence_of :employee_leave_type_id
  validates_presence_of :leave_count, :if => :check_leave_count
  validate :leave_count
  
  before_create :set_update_group
  before_destroy :set_update_group
  
  def validate
    unless leave_count.to_f%0.5 == 0.0 
      errors.add(:leave_count, :leave_count_as_whole_numbers)
    end
  end
  
  def check_leave_count
    leave_type_id = self.employee_leave_type_id
    leave_type = EmployeeLeaveType.find(leave_type_id)
    credit_type = leave_type.credit_type
    unless credit_type == "Slab"
      unless leave_count.present?
        return true
      end
    end
  end
  
  def display_leave_count
    if leave_count.present?
      ("%g" % ("%.2f" % leave_count)) 
    else
      leave_type =  EmployeeLeaveType.find(employee_leave_type_id)
      return leave_type.max_leave_count if leave_type.credit_type == 'flat'
    end
  end
  
  def set_update_group
    self.update_group = true
  end
  
end
