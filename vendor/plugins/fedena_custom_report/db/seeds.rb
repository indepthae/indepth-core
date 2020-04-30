Privilege.reset_column_information
Privilege.find_or_create_by_name(:name => 'CustomReportControl',:description => 'custom_report_control_privilege')
Privilege.find_or_create_by_name(:name => 'CustomReportView',:description => 'custom_report_view_privilege')
if Privilege.column_names.include?("privilege_tag_id")
  Privilege.find_by_name('CustomReportControl').update_attributes(:privilege_tag_id=>PrivilegeTag.find_by_name_tag('administration_operations').id, :priority=>150 )
  Privilege.find_by_name('CustomReportView').update_attributes(:privilege_tag_id=>PrivilegeTag.find_by_name_tag('administration_operations').id, :priority=>160 )
end

menu_link_present = MenuLink rescue false
unless menu_link_present == false
  reports_category = MenuLinkCategory.find_by_name("data_and_reports")
  MenuLink.create(:name=>'custom_reports',:target_controller=>'custom_reports',:target_action=>'index',:higher_link_id=>nil,:icon_class=>'report-icon',:link_type=>'general',:user_type=>nil,:menu_link_category_id=>reports_category.id) unless MenuLink.exists?(:name=>'custom_reports')
end