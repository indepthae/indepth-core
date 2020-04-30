Privilege.reset_column_information
Privilege.find_or_create_by_name :name => "DocumentManager",:description=>"document_manager_privilege"
if Privilege.column_names.include?("privilege_tag_id")
  Privilege.find_by_name('DocumentManager').update_attributes(:privilege_tag_id=>PrivilegeTag.find_by_name_tag('administration_operations').id, :priority=> 400 )
end
FolderAssignmentType.find_or_create_by_name :name => "Student", :description => "Student"
FolderAssignmentType.find_or_create_by_name :name => "Employee", :description => "Employee"

menu_link_present = MenuLink rescue false
unless menu_link_present == false
  reports_category = MenuLinkCategory.find_by_name("collaboration")
  MenuLink.create(:name=>'doc_manager_text',:target_controller=>'doc_managers',:target_action=>'index',:higher_link_id=>nil,:icon_class=>'doc-manager-icon',:link_type=>'general',:user_type=>nil,:menu_link_category_id=>reports_category.id) unless MenuLink.exists?(:name=>'doc_manager_text')
  MenuLink.create(:name=>'share_docs',:target_controller=>'doc_managers',:target_action=>'share_docs',:higher_link_id=>MenuLink.find_by_name('doc_manager_text').id,:icon_class=>nil,:link_type=>'general',:user_type=>nil,:menu_link_category_id=>reports_category.id) unless MenuLink.exists?(:name=>'share_docs')
end
