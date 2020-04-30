privilege_tags = PrivilegeTag.all(:conditions => "priority > 1", :order => :priority)
privilege_tags.each do |tags|
  tags.update_attributes(:priority => (tags.priority + 1))
end

privilege_tag = PrivilegeTag.find_or_create_by_name_tag(:name_tag => 'hr_management', :priority => 2)

hr_basics = Privilege.find_by_name('HrBasics')
hr_basics.update_attributes(:name => 'HrSettings', :description => 'hr_settings_privilege', :privilege_tag_id => privilege_tag.id) if hr_basics.present?

manage_employee = Privilege.find_or_create_by_name(:name => 'ManageEmployee', :description => 'manage_employee_privilege', :privilege_tag_id => privilege_tag.id, :priority => 55)

payslip_powers = Privilege.find_by_name('PayslipPowers')
payslip_powers.update_attributes(:name => 'PayrollAndPayslip', :description => 'payroll_and_payslip_privilege', :privilege_tag_id => privilege_tag.id, :priority => 60) if payslip_powers.present?

employee_attendance = Privilege.find_by_name('EmployeeAttendance')
employee_attendance.update_attributes(:privilege_tag_id => privilege_tag.id, :priority => 65) if employee_attendance.present?

employee_search = Privilege.find_by_name('EmployeeSearch')
employee_search.update_attributes(:privilege_tag_id => privilege_tag.id, :priority => 70) if employee_search.present?

employee_reports = Privilege.find_or_create_by_name(:name => 'EmployeeReports', :description => 'employee_reports_privilege', :privilege_tag_id => privilege_tag.id, :priority => 80)

schools = School.all
schools.each do |school|
  MultiSchool.current_school = school
  hr_settings = Privilege.find_by_name('HrSettings')
  payslip_powers = Privilege.find_by_name('PayrollAndPayslip')
  manage_employee = Privilege.find_by_name('ManageEmployee')
  employee_attendance = Privilege.find_by_name('EmployeeAttendance')
  employee_search = Privilege.find_by_name('EmployeeSearch')
  employee_reports = Privilege.find_by_name('EmployeeReports')
  
  hr_settings_users = hr_settings.users

  manage_employee.users = hr_settings_users

  payslip_powers_users = payslip_powers.users

  employee_attendance_users = employee_attendance.users

  employee_search_users = employee_search.users

  employee_reports.users = hr_settings_users & payslip_powers_users & employee_attendance_users & employee_search_users
end


menu_link_present = MenuLink rescue false
unless menu_link_present == false
  cat = MenuLinkCategory.find_by_name("administration")
  unless cat.nil?
    a = cat.allowed_roles
    a.reject!{|j|  (j == :payslip_powers or j == :hr_basics)}
    a += [:hr_settings, :payroll_and_payslip, :manage_employee, :employee_reports]
    a.flatten!
    cat.allowed_roles = a.uniq
    cat.save
  end
  data_cat = MenuLinkCategory.find_by_name("data_and_reports")
  unless data_cat.nil?
    a = data_cat.allowed_roles
    a.push(:employee_reports)
    a.flatten!
    data_cat.allowed_roles = a.uniq
    data_cat.save
  end
  
end


academics_category = MenuLinkCategory.find_by_name("academics")
leaves_link = MenuLink.find_by_name('leaves')
leaves_link.update_attributes({:target_action => 'employee_leaves'})
MenuLink.create(:name=>'apply_leave',:target_controller=>'employee_attendance',:target_action=>'leaves',:higher_link_id=>leaves_link.id,:icon_class=>nil,:link_type=>'own',:user_type=>'employee',:menu_link_category_id=>academics_category.id) unless MenuLink.exists?(:name=>'apply_leave')
MenuLink.create(:name=>'my_leaves',:target_controller=>'employee_attendance',:target_action=>'my_leaves',:higher_link_id=>leaves_link.id,:icon_class=>nil,:link_type=>'own',:user_type=>'employee',:menu_link_category_id=>academics_category.id) unless MenuLink.exists?(:name=>'my_leaves')
MenuLink.create(:name=>'reportees_leaves',:target_controller=>'employee_attendance',:target_action=>'reportees_leaves',:higher_link_id=>leaves_link.id,:icon_class=>nil,:link_type=>'own',:user_type=>'employee',:menu_link_category_id=>academics_category.id) unless MenuLink.exists?(:name=>'reportees_leaves')
MenuLink.create(:name=>'pending_leave_applications',:target_controller=>'employee_attendance',:target_action=>'pending_leave_applications',:higher_link_id=>leaves_link.id,:icon_class=>nil,:link_type=>'own',:user_type=>'employee',:menu_link_category_id=>academics_category.id) unless MenuLink.exists?(:name=>'pending_leave_applications')

#Menu link HR settings changing name
hr = MenuLink.find_by_name('human_resource')
setting = MenuLink.find_by_name('setting',:conditions => ["higher_link_id = ?", hr.id])
setting.update_attribute(:name, "hr_setting")
