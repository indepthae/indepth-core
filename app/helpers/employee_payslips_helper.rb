module EmployeePayslipsHelper

  def link_to_actions(emp,assigned, action_num, current_group, fin_flag, employee_name, payroll_group)
    html = ''
    action = params[:action]

    if action == 'assigned_employees' or (action == 'employee_list' && assigned)
      html += current_group == false ? "<span class='warning_sym' tooltip='#{t('outdated_payroll')}'></span>" : "<span class='substitute'></span>"
      html += link_to "#{t('view_payroll')}",{:controller => "payroll", :action => "show", :emp_id => emp.id, :from => "assigned_employees", :finance => fin_flag}
      if fin_flag.nil? and permitted_to? :remove_from_payroll_group, :payroll
        unless emp.pending_payslips_present
          html += link_to t('remove_from_group'),{:controller => "payroll", :action => "remove_from_payroll_group", :id => params[:id], :employee_id => emp.id}, :id => "remove_link", :onclick => "return make_popup_box(this, 'confirm', '#{t('remove_employee_confirmation_message', {:name => employee_name})}',{'ok' : '#{t('remove_employee')}', 'cancel' : '#{t('cancel')}', 'title' : '#{t('remove_employee')}'});"
        else
          html += link_to_remote t('remove_from_group'), :url => {:controller => "payroll", :action => "show_warning", :id => params[:id], :employee_id => emp.id, :from => "assigned_employees"}, :html => {:id => "remove_link"}
        end
      end
    elsif action == 'assign_employees' or action == 'employee_list'
      case action_num
      when 0
        html += link_to t('add_to_this_group'),{:controller => "payroll", :action => "create_employee_payroll", :id => params[:id], :employee_id => emp.id, :from => 'assign_employees'}
      when 1
        html += current_group == false ? "<span class='warning_sym' tooltip='#{t('outdated_payroll')}'></span>" : "<span class='substitute'></span>"
        html += link_to "#{t('view_payroll')}",{:controller => "payroll", :action => "show", :emp_id => emp.id, :from => 'assigned_employees', :finance => fin_flag}
        if fin_flag.nil? and permitted_to? :remove_from_payroll_group, :payroll
          unless emp.pending_payslips_present
            html += link_to t('remove_from_group'), {:controller => "payroll", :action => "remove_from_payroll_group", :id => params[:id], :employee_id => emp.id, :from => 'assign_employees'}, :id => "remove_link", :onclick => "return make_popup_box(this, 'confirm', '#{t('remove_employee_confirmation_message', {:name => employee_name})}',{'ok' : '#{t('remove_employee')}', 'cancel' : '#{t('cancel')}', 'title' : '#{t('remove_employee')}'});"
          else
            html += link_to_remote t('remove_from_group'), :url => {:controller => "payroll", :action => "show_warning", :id => params[:id], :employee_id => emp.id, :from => 'assign_employees'}, :html => {:id => "remove_link"}
          end
        end
      when 2
        unless emp.pending_payslips_present
          html += link_to t('change_payroll_group'),{:controller => "payroll", :action => "create_employee_payroll", :id => params[:id], :employee_id => emp.id, :from => 'assign_employees'}
        else
          html += link_to_remote t('change_payroll_group'), :url => {:controller => "payroll", :action => "show_warning", :id => params[:id], :employee_id => emp.id, :from => 'assign_employees'}, :html => {:id => "remove_link"}
        end
      end
    end
    html.html_safe
  end

end
