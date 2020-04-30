class DelayedEmployeeLeave <  Struct.new(:parameters, :leave_reset_id, :retry_flag, :leave_type_ids)
  def perform
    emp_ids = JSON.parse(parameters)
    @employees = Employee.find(:all , :conditions => ["id IN (?)",emp_ids], :include => {:leave_group => :leave_group_leave_types})
    update_employee_leaves(leave_reset_id, retry_flag,leave_type_ids )
  end

  def update_employee_leaves(leave_reset_id, retry_flag,leave_type_ids)
    reset_logs = LeaveReset.find(leave_reset_id)
    leave_year = LeaveYear.find(reset_logs.leave_year_id) if reset_logs.leave_year_id
    leave_year_id = leave_year.present? ? leave_year.id : nil
    action = "reset"
    description = "Leave reset while end year process for #{leave_year.name} at #{Date.today}" if leave_year.present?
    ignore_lop = Configuration.ignore_lop
    ignore_lop = ignore_lop.config_value
    leave_types = EmployeeLeaveType.find(:all, :conditions => ["id IN (?)",leave_type_ids])
      ActiveRecord::Base.transaction do
          leave_types.each do |type|
              EmployeeLeaveType.create_credit_record(type, reset_logs.reset_date)
            end
    @employees.each do |employee|
      errors = []
      reasons = []
      reasons_leave_type = []
      leave_type_to_be_reset=[]
      employee_reset_logs = LeaveResetLog.find_all_by_employee_id_and_retry_status(employee.id,true)
        emp_log = LeaveResetLog.new({:employee_id => employee.id, :status => 1, :leave_reset_id => leave_reset_id, :leave_year_id => leave_year_id})
        emp_leaves = EmployeeLeave.find_all_by_employee_id_and_employee_leave_type_id(employee.id,leave_type_ids)
        inactive_leaves = EmployeeLeaveType.all(:conditions => ["is_active = false"])
        all_leaves = EmployeeLeave.find_all_by_employee_id(employee.id)
        leave_group = employee.leave_group
        previous_reset_date = employee.last_reset_date.to_date
        leave_type_ids.each do |lt_id|
          emp_leave = EmployeeLeave.find_by_employee_id_and_employee_leave_type_id(employee.id,lt_id)
          if emp_leave.present?
            if reset_logs.reset_date < emp_leave.reset_date
              reasons_leave_type << emp_leave.employee_leave_type.name + ": reset_date_overlap"
            else
              leave_type_to_be_reset << lt_id
            end
          else
            leave_type_to_be_reset << lt_id
          end
        end
        emp_additional_leaves = employee.employee_additional_leaves.select{|e| e.is_deductable == true }
        unless retry_flag
          non_deducted_lops = emp_additional_leaves.collect{|e| e.is_deducted if e.attendance_date >= previous_reset_date}.include? false
          if ignore_lop == "true" && non_deducted_lops
            if reasons_leave_type.present?
              reasons_leave_type << "pending_leave_applications"
            else
              reasons << "non_deducted_lop_present"
            end
          end
        end
        pending_leave_applications = employee.apply_leaves.all(:conditions => ["approved  IS NULL"])
        if pending_leave_applications.present?
          if reasons_leave_type.present?
            reasons_leave_type << "pending_leave_applications"
          else
            reasons << "pending_leave_applications"
          end
        end
        if employee.joining_date <= reset_logs.reset_date
          if reasons_leave_type.empty?
            if reasons.empty?
              if leave_group.present?
                leave_types = leave_group.leave_group_leave_types.find_all_by_employee_leave_type_id(leave_type_to_be_reset)
                leave_types_id = leave_types.collect(&:employee_leave_type_id)
                emp_leave_types = EmployeeLeaveType.find(:all, :conditions => ["id IN (?)", leave_types_id])
                unless emp_leaves.present? 
                  emp_leave_types.each do |t|
                    leave_count = EmployeeLeaveType.leave_count(t,reset_logs.reset_date, leave_group)
                    e = EmployeeLeave.new(:employee_id => employee.id, :employee_leave_type_id => t.id, :leave_group_id => leave_group.id, :leave_count => leave_count, :leave_taken => 0, :reset_date => reset_logs.reset_date,:reseted_at=> Time.now,:additional_leaves => 0, :is_additional => false)
                    errors << e.errors.full_messages unless e.save
                    error = EmployeeLeaveBalance.create_employee_leave_balance_record(employee.id, t.id, 0, reset_logs.reset_date, leave_count, false, 0, 0, leave_year_id, action,description)
                    errors << error if error.present?
                  end
                else
                  all_e_types = EmployeeLeave.find_all_by_employee_id(employee.id)
                  removed_type_ids = all_e_types.collect(&:employee_leave_type_id) - leave_group.leave_group_leave_types.collect(&:employee_leave_type_id)
                  g_type_ids = leave_types.collect(&:employee_leave_type_id)
                  e_type_ids = emp_leaves.collect(&:employee_leave_type_id)
                  emp_leave_types.each do |type|
                    leave_count = EmployeeLeaveType.leave_count(type,reset_logs.reset_date, leave_group)
                    if e_type_ids.include? type.id
                      emp_lev = emp_leaves.detect{|e| e.employee_leave_type_id == type.id }
                      current_leaves_taken = emp_lev.leave_taken
                      current_additional_leaves = emp_lev.additional_leaves
                      leave_type = type
                      default_leave_count = leave_count
                      if leave_type.carry_forward
                        carry_forward_leave = leave_type.carry_forward_type
                        leave_taken = emp_lev.leave_taken
                        available_leave = emp_lev.leave_count
                        if leave_taken <= available_leave
                          balance_leave = available_leave - leave_taken
                          leaves_added = 0
                          if carry_forward_leave == 2
                            if balance_leave >= leave_type.max_carry_forward_leaves.to_f
                              new_count = leave_type.max_carry_forward_leaves
                              leaves_added = new_count.to_f + default_leave_count.to_f - balance_leave
                            else
                              new_count = balance_leave
                              leaves_added = default_leave_count.to_f
                            end
                          elsif carry_forward_leave == 1
                            new_count = balance_leave
                            leaves_added = default_leave_count.to_f
                          end
                          available_leave = new_count.to_f
                          available_leave += default_leave_count.to_f
                          leave_taken = 0
                          add_leaves = 0
                          errors << emp_lev.errors.full_messages unless emp_lev.update_attributes(:additional_leaves => add_leaves,:reseted_at=> Time.now ,:leave_taken => leave_taken,:leave_count => available_leave, :reset_date => reset_logs.reset_date, :is_active => true, :leave_group_id => leave_group.id, :is_additional => false)
                          error = EmployeeLeaveBalance.create_employee_leave_balance_record(employee.id, type.id, balance_leave, reset_logs.reset_date, leaves_added,false, current_leaves_taken, current_additional_leaves, leave_year_id, action, description)
                          errors << error if error.present?
                        else
                          available_leave = default_leave_count.to_f
                          leave_taken = 0
                          add_leaves = 0
                          errors << emp_lev.errors.full_messages unless emp_lev.update_attributes(:additional_leaves => add_leaves,:reseted_at => Time.now,:leave_taken => leave_taken,:leave_count => available_leave, :reset_date => reset_logs.reset_date, :is_active => true, :leave_group_id => leave_group.id, :is_additional => false)
                          error = EmployeeLeaveBalance.create_employee_leave_balance_record(employee.id, type.id, balance_leave, reset_logs.reset_date, leaves_added, false, current_leaves_taken, current_additional_leaves, leave_year_id, action, description)
                          errors << error if error.present?
                        end
                      else
                        available_leave = default_leave_count.to_f
                        leave_taken = 0
                        add_leaves = 0
                        emp_leave_taken = emp_lev.leave_taken
                        emp_leave_count = emp_lev.leave_count
                        balance = emp_leave_count - emp_leave_taken
                        leaves_added = leave_count - balance
                        errors << emp_lev.errors.full_messages unless emp_lev.update_attributes(:additional_leaves => add_leaves,:reseted_at => Time.now, :leave_taken => leave_taken,:leave_count => available_leave, :reset_date => reset_logs.reset_date, :is_active => true, :leave_group_id => leave_group.id, :is_additional => false)
                        error = EmployeeLeaveBalance.create_employee_leave_balance_record(employee.id, type.id, balance, reset_logs.reset_date, leaves_added,false, current_leaves_taken, current_additional_leaves, leave_year_id, action, description)
                        errors << error if error.present?
                      end
                    else
                      emp_lev = EmployeeLeave.new(:employee_id => employee.id, :employee_leave_type_id => type.id, :leave_group_id => leave_group.id, :leave_count => leave_count, :leave_taken => 0, :reset_date => reset_logs.reset_date,:reseted_at=> Time.now, :additional_leaves => 0, :is_additional => false)
                      errors << emp_lev.errors.full_messages unless emp_lev.save
                      error = EmployeeLeaveBalance.create_employee_leave_balance_record(employee.id, type.id, 0.0, reset_logs.reset_date, leave_count,false, 0.0, 0.0, leave_year_id,action, description)
                      errors << error if error.present?
                    end
                  end
                  removed_type_ids.each do |r_type|
                    emp_lev = all_e_types.detect{|e| e.employee_leave_type_id == r_type }
                    emp_leave_taken = emp_lev.leave_taken
                    emo_addl_leave = emp_lev.additional_leaves
                    emp_leave_count = emp_lev.leave_count
                    balance = emp_leave_count - emp_leave_taken
                    leaves_added = 0 - balance
                    errors << emp_lev.errors.full_messages unless emp_lev.update_attributes(:additional_leaves => 0,:reseted_at=> Time.now ,:leave_taken => 0,:leave_count => 0, :reset_date => reset_logs.reset_date, :is_active => false, :leave_group_id => nil)
                    error = EmployeeLeaveBalance.create_employee_leave_balance_record(employee.id, emp_lev.employee_leave_type_id, balance, reset_logs.reset_date, leaves_added, true, emp_leave_taken, emo_addl_leave, leave_year_id, action, description)
                    errors << error if error.present?
                  end
                end
              else
                if all_leaves.present?
                  all_leaves.each do |e|
                    emp_leave_taken = e.leave_taken
                    emp_addl_leaves = e.additional_leaves
                    emp_leave_count = e.leave_count
                    balance = emp_leave_count - emp_leave_taken
                    leaves_added = 0-balance
                    errors << e.errors.full_messages unless e.update_attributes(:additional_leaves => 0,:reseted_at=> Time.now ,:leave_taken => 0,:leave_count => 0, :reset_date => reset_logs.reset_date, :is_active => false, :leave_group_id => nil)
                    error = EmployeeLeaveBalance.create_employee_leave_balance_record(employee.id, e.employee_leave_type_id, balance, reset_logs.reset_date, leaves_added,true, emp_leave_taken, emp_addl_leaves, leave_year_id, action, description)
                    errors << error if error.present?
                  end
                end
              end
              if inactive_leaves.present?
                inactive_leaves.each do |lt|
                  emp_lev = all_leaves.detect{|e| e.employee_leave_type_id == lt.id }
                  if emp_lev.present?
                    emp_leave_taken = emp_lev.leave_taken
                    emp_addl_leaves = emp_additional_leaves
                    emp_leave_count = emp_lev.leave_count
                    balance = emp_leave_count.to_f - emp_leave_taken.to_f
                    leaves_added  = 0.to_f - balance.to_f
                    error = EmployeeLeaveBalance.create_employee_leave_balance_record(employee.id, lt.id, balance, reset_logs.reset_date, leaves_added,true, emp_leave_taken, emp_addl_leaves, leave_year_id, action, description)
                    errors << error if error.present?
                  end
                  errors << emp_lev.errors.full_messages unless emp_lev.update_attributes(:additional_leaves => 0,:reseted_at=> Time.now ,:leave_taken => 0,:leave_count => 0, :reset_date => reset_logs.reset_date, :is_active => (g_type_ids.present? ? (g_type_ids.include? lt.id) : false), :leave_group_id => nil, :is_additional => false) if emp_lev.present?
                end
              end
              if errors.empty?
                emp_log.status = 2
              else
                emp_log.status = 3
                reasons << "technical_error"
              end
              employee.update_attribute("last_reset_date",reset_logs.reset_date) if reasons.empty?
            else
              emp_log.status = 3
            end
          else
            emp_log.status = 4
          end
        else
          emp_log.status = reasons_leave_type.present? ? 4 : 3
          reasons << "reset_date_before_joining_date"
        end
        unless reasons_leave_type.present?
          emp_log.retry_status = true if reasons.count == 1 && reasons.include?("non_deducted_lop_present")
          emp_log.reason = reasons
        else
          emp_log.retry_status = true if reasons_leave_type.count == 1 && reasons_leave_type.include?("non_deducted_lop_present")
          emp_log.reason = reasons_leave_type
        end
        emp_log.save
        employee_reset_logs.each do |emp|
          emp.update_attribute("retry_status", false)
        end
        raise ActiveRecord::Rollback unless errors.empty?
      end
    end
    emp_reset_logs = reset_logs.leave_reset_logs
    if emp_reset_logs.collect{|l| l.status}.uniq.length == 1 && (emp_reset_logs.collect{|l| l.status}.include? 2)
      reset_logs.update_attribute("status", 2)
    elsif emp_reset_logs.collect{|l| l.status}.include? 3
      reset_logs.update_attribute("status", 3)
    end
    if emp_reset_logs.collect{|l| l.status}.include? 4
      emp_reset_logs.each do |log|
        if log.status == 4
          if log.reason.present?
            reset_logs.update_attribute("status", 3)
            log.update_attribute("status", 3)
          else
            log.update_attribute("status", 2)
            reset_logs.update_attribute("status", 2)
          end
        end
      end
    end
  end
end
