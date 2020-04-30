Privilege.reset_column_information
Privilege.find_or_create_by_name :name => "DataManagement",:description => "data_management_privilege"
Privilege.find_or_create_by_name :name => "DataManagementViewer",:description => "data_management_viewer_privilege"
if Privilege.column_names.include?("privilege_tag_id")
  Privilege.find_by_name('DataManagement').update_attributes(:privilege_tag_id=>PrivilegeTag.find_by_name_tag('administration_operations').id, :priority=>210 )
  Privilege.find_by_name('DataManagementViewer').update_attributes(:privilege_tag_id=>PrivilegeTag.find_by_name_tag('administration_operations').id, :priority=>220 )
end

menu_link_present = MenuLink rescue false
unless menu_link_present == false
  reports_category = MenuLinkCategory.find_by_name("data_and_reports")
  MenuLink.create(:name=>'data_management_label',:target_controller=>'school_assets',:target_action=>'index',:higher_link_id=>nil,:icon_class=>'data-management-icon',:link_type=>'general',:user_type=>nil,:menu_link_category_id=>reports_category.id) unless MenuLink.exists?(:name=>'data_management_label')
end

