class DelayedUpdateEmployeeLeave <  Struct.new(:id, :leave_credit_id, :leave_type_ids ,:saved_emp, :flag, :removed_leave_type)
  
  def perform
    @employees = Employee.find(:all, :conditions => ["id IN (?)",saved_emp], :include => {:leave_group => :leave_group_leave_types})
    update_employee_leaves(id,leave_credit_id,leave_type_ids, flag, removed_leave_type )
  end

  def update_employee_leaves(id,leave_credit_id,leave_type_ids, flag, removed_leave_type)
    leave_group = LeaveGroup.find(id)
    leave_types = EmployeeLeaveType.find(:all, :conditions => ["id IN (?)", leave_type_ids])
    #  removed_leave_types = EmployeeLeaveType.find(:all, :conditions => ["id IN (?)", removed_leave_type])
    credit_logs = LeaveCredit.find(leave_credit_id)
    leave_year = LeaveYear.active.first
    action = "credit"
    ActiveRecord::Base.transaction do
      #      if flag
      #        leave_types.each do |type|
      #          EmployeeLeaveType.create_credit_record(type, credit_logs.credited_date)
      #        end
      #      end
      #      removed_leave_types.each do |type|
      #        EmployeeLeaveType.update_credit_record(type, credit_logs.credited_date)
      #      end
      @employees.each do |employee|
        errors = []
        reasons = []
        employee_credit_logs = LeaveCreditLog.find_all_by_employee_id_and_retry_status(employee.id,true)
        emp_log = LeaveCreditLog.new({:employee_id => employee.id, :status => 1, :leave_credit_id => leave_credit_id})
        emp_leave = EmployeeLeave.find_all_by_employee_id_and_employee_leave_type_id(employee.id,leave_type_ids)
        description = "leave type added to the leave group #{leave_group.name} manualy" if flag
        description = "New Employee added to the leave group #{leave_group.name} manualy" unless flag == true
        previous_reset_date = employee.last_reset_date.to_date
        if employee.joining_date <= credit_logs.credited_date.to_date
          if reasons.empty?
            leave_types.each do |type|
              leave_count = EmployeeLeaveType.leave_count(type,credit_logs.credited_date, leave_group)
              emp_lev = emp_leave.detect{|e| e.employee_leave_type_id == type.id }
              if emp_lev.present?
                previous_reset_date = emp_lev.reset_date.to_date
                leaves_taken = emp_lev.leave_taken
                current_additional_leaves = emp_lev.additional_leaves
                default_leave_count = leave_count
                available_leave = emp_lev.leave_count
                available_leave += default_leave_count.to_f
                add_leaves = current_additional_leaves
                balance_leave = available_leave - leaves_taken
                errors << emp_lev.errors.full_messages unless emp_lev.update_attributes(:additional_leaves => add_leaves,:reseted_at=> Time.now,:leave_taken => leaves_taken,:leave_count => available_leave, :reset_date => previous_reset_date, :is_active => true, :leave_group_id => id, :is_additional => false)
                error = EmployeeLeaveBalance.create_employee_leave_balance_record(employee.id, type.id, balance_leave, credit_logs.credited_date, leave_count, false, leaves_taken, add_leaves, leave_year.id, action, description)
                errors << error if error.present?
              else
                e = EmployeeLeave.new(:employee_id => employee.id, :employee_leave_type_id => type.id, :leave_group_id =>  leave_group.id, :leave_count => leave_count, :leave_taken => 0, :reset_date => previous_reset_date,:reseted_at=> Time.now, :additional_leaves => 0, :is_additional => false)
                errors << e.errors.full_messages unless e.save
                error = EmployeeLeaveBalance.create_employee_leave_balance_record(employee.id, type.id, 0, credit_logs.credited_date, leave_count, false, 0, 0, leave_year.id, action, description)
                errors << error if error.present?
              end
            end
            all_e_types = EmployeeLeave.find_all_by_employee_id(employee.id)
            removed_leave_type.each do |r_type|
              emp_lev = all_e_types.detect{|e| e.employee_leave_type_id == r_type }
              emp_leave_taken = emp_lev.leave_taken
              emo_addl_leave = emp_lev.additional_leaves
              emp_leave_count = emp_lev.leave_count
              balance = emp_leave_count - emp_leave_taken
              leaves_added = 0 - balance
              errors << emp_lev.errors.full_messages unless emp_lev.update_attributes(:additional_leaves => 0,:reseted_at=> Time.now ,:leave_taken => 0,:leave_count => 0, :reset_date => credit_logs.credited_date, :is_active => false, :leave_group_id => nil)
              error = EmployeeLeaveBalance.create_employee_leave_balance_record(employee.id, emp_lev.employee_leave_type_id, balance, credit_logs.credited_date, leaves_added, true, emp_leave_taken, emo_addl_leave, leave_year.id, action, description)
              errors << error if error.present?
            end
           
            if errors.empty?
              emp_log.status = 2
            else
              emp_log.status = 3
              reasons << "technical_error"
            end
            employee.update_attribute("last_credit_date", credit_logs.credited_date) if reasons.empty?
          else
            emp_log.status = 3
          end
        else
          emp_log.status = 3
          reasons << "credit_date_before_joining_date"
        end
        emp_log.save
        employee_credit_logs.each do |emp|
          emp.update_attribute("retry_status", false)
        end
      end
    end
    emp_credit_logs = credit_logs.leave_credit_logs
    if emp_credit_logs.collect{|l| l.status}.uniq.length == 1 && (emp_credit_logs.collect{|l| l.status}.include? 2)
      credit_logs.update_attribute("status", 2)
    elsif emp_credit_logs.collect{|l| l.status}.include? 3
      credit_logs.update_attribute("status", 3)
    end
    if emp_credit_logs.collect{|l| l.status}.include? 4
      emp_credit_logs.each do |log|
        if log.status == 4
          if log.reason.present?
            credit_logs.update_attribute("status", 3)
            log.update_attribute("status", 3)
          else
            log.update_attribute("status", 2)
            credit_logs.update_attribute("status", 2)
          end
        end
      end
    end
  
  end
     
end
