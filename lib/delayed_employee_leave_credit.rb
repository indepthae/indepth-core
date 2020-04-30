class DelayedEmployeeLeaveCredit <  Struct.new(:parameters, :leave_credit_id, :leave_type_ids)
  
  # Manual credit
  
  def perform
    emp_ids = JSON.parse(parameters)
    @employees = Employee.find(:all , :conditions => ["id IN (?)",emp_ids], :include => {:leave_group => :leave_group_leave_types})
    employee_leaves_credit(leave_credit_id,leave_type_ids)
  end

  def  employee_leaves_credit(leave_credit_id,leave_type_ids)
    log = Logger.new("log/credit_leave.log")
    leave_types = EmployeeLeaveType.find(:all, :conditions => ["id IN (?)", leave_type_ids])
    credit_logs = LeaveCredit.find(leave_credit_id)
    leave_year = LeaveYear.active.first
    action = "credit"
    description = "Manual Leave credit"
    ActiveRecord::Base.transaction do
      #      leave_types.each do |type|
      #        EmployeeLeaveType.create_credit_record(type, credit_logs.credited_date)
      #      end
      @employees.each do |employee|
        errors = []
        reasons = []
        employee_credit_logs = LeaveCreditLog.find_all_by_employee_id_and_retry_status(employee.id,true)
        emp_log = LeaveCreditLog.new({:employee_id => employee.id, :status => 1, :leave_credit_id => leave_credit_id})
        emp_leave = EmployeeLeave.find_all_by_employee_id_and_employee_leave_type_id(employee.id,leave_type_ids)
        #  inactive_leaves = EmployeeLeaveType.all(:conditions => ["is_active = false"])
        all_special_leaves = EmployeeLeave.find_all_by_employee_id_and_is_additional(employee.id, true)
        previous_reset_date = employee.last_reset_date.to_date
        #  emp_additional_leaves = employee.employee_additional_leaves.select{|e| e.is_deductable == true }
        leave_group = employee.leave_group
        if reasons.empty?
          if leave_group.present?
            leave_types.each do |type|
              group_leave_types =  leave_group.leave_group_leave_types
              group_leave_types_ids = group_leave_types.collect(&:employee_leave_type_id)
              if group_leave_types_ids.include?(type.id)
                leave_count = EmployeeLeaveType.leave_count(type,credit_logs.credited_date, leave_group)
                emp_lev = emp_leave.detect{|e| e.employee_leave_type_id == type.id }
                if emp_lev.present?
                  previous_reset_date = emp_lev.reset_date
                  leaves_taken = emp_lev.leave_taken
                  current_additional_leaves = emp_lev.additional_leaves
                  default_leave_count = leave_count
                  available_leave = emp_lev.leave_count
                  available_leave += default_leave_count.to_f
                  leave_balance = available_leave - leaves_taken
                  errors << emp_lev.errors.full_messages unless emp_lev.update_attributes(:additional_leaves => current_additional_leaves,:reseted_at=> Time.now,:leave_taken => leaves_taken,:leave_count => available_leave, :reset_date =>  previous_reset_date, :is_active => true, :leave_group_id => id, :is_additional => false)
                  error = EmployeeLeaveBalance.create_employee_leave_balance_record(employee.id, type.id, leave_balance, credit_logs.credited_date, leave_count, false, leaves_taken, current_additional_leaves, leave_year.id, action, description)
                  errors << error if error.present?
                else
                  e = EmployeeLeave.new(:employee_id => employee.id, :employee_leave_type_id => type.id, :leave_group_id =>  leave_group.id, :leave_count =>  leave_count, :leave_taken => 0, :reset_date => previous_reset_date,:reseted_at=> Time.now, :additional_leaves => 0, :credited_at => Time.now,:is_additional => false)
                  errors << e.errors.full_messages unless e.save
                  error = EmployeeLeaveBalance.create_employee_leave_balance_record(employee.id, type.id, 0, credit_logs.credited_date, leave_count, false, 0, 0, leave_year.id, action, description)
                  errors << error if error.present?
                end
              else
                emp_log.status = 3
                reasons << I18n.t('not_assign_with_leave_type', :leave_name => type.name)
              end
            end
          else
            emp_log.status = 3
            reasons << I18n.t('not_assign_to_leave_group')
          end
          if all_special_leaves.present?
            all_special_leaves.each do |e|
              emp_leave_taken = e.leave_taken
              emp_addl_leaves = e.additional_leaves
              emp_leave_count = e.leave_count
              balance = emp_leave_count - emp_leave_taken
              leaves_added = 0-balance
              errors << e.errors.full_messages unless e.update_attributes(:additional_leaves => 0,:reseted_at=> Time.now ,:leave_taken => 0,:leave_count => 0, :reset_date => credit_logs.credited_date, :is_active => false, :leave_group_id => nil)
              error = EmployeeLeaveBalance.create_employee_leave_balance_record(employee.id, e.employee_leave_type_id, balance, credit_logs.credited_date, leaves_added,true, emp_leave_taken, emp_addl_leaves, leave_year.id, action, description)
              errors << error if error.present?
            end
          end
          if errors.empty? and reasons.empty?
            emp_log.status = 2
          elsif errors.present?
            reasons << "technical_error"
          end            
          employee.update_attribute("last_credit_date", credit_logs.credited_date) if reasons.empty?
        else
          emp_log.status = 3
        end
        emp_log.reason = reasons
        emp_log.save
        employee_credit_logs.each do |emp|
          emp.update_attribute("retry_status", false)
        end
        raise ActiveRecord::Rollback unless errors.empty?
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