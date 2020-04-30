module LeaveYearsHelper
  
  def fetch_ly_path(l_year)
    l_year.new_record? ? leave_years_path : leave_year_path
  end
  
  def form_type(type)
    if type == "reset_setting"
      return "remote_form_for"
    else
      return "form_for"
    end
    
  end
  
  def setting_label1(type)
    if type == "automatic"
      return "automatic"
    elsif  type == "credit_date"
      return "custom_based"
    elsif type == "reset_setting"
      return "updated_reset"
    end
  end
  
  def setting_label2(type)
    if type == "automatic"
      return "manual_entry"
    elsif  type == "credit_date"
      return "calendar_based"
    elsif type == "reset_setting"
      return "current_reset"
    end
  end
  
  
  def year_action_name(type)
    if type == "automatic"
      return "settings"
    elsif  type == "credit_date"
      return "leave_credit_date_settings"
    elsif type == "reset_setting"
      return "confirmation_box"
    end
    
  end
  
  def label_desc1(type)
    if type == "automatic"
      return "automatic_decs"
    elsif  type == "credit_date"
      return "custom_based_desc"
    elsif type == "reset_setting"
      return "updated_reset_decs"
    end
  end
  
  def label_desc2(type)
    if type == "automatic"
      return "manual_decs"
    elsif  type == "credit_date"
      return "calendar_based_desc"
    elsif type == "reset_setting"
      return "current_reset_decs"
    end
  end
  
  
  def check_dependencies(leave_year)
    end_reset = LeaveReset.find_by_leave_year_id(leave_year.id)
    if end_reset.present? 
      return true
    else
      return false 
    end
  end
  
  
  def emp_count(dept)
    dept.employees.to_a.select{|e| e.leave_reset_logs.present?}.count  
  end
  
end
