Privilege.reset_column_information
Privilege.find_or_create_by_name(:name => "Tokens", :description=>"tokens_privilege")
Privilege.find_or_create_by_name(:name => "Oauth2Manage", :description=>"oauth2_manage_privilege")
if Privilege.column_names.include?("privilege_tag_id")
  Privilege.find_by_name('Tokens').update_attributes(:privilege_tag_id => PrivilegeTag.find_by_name_tag('administration_operations').id, :priority=>192)
  Privilege.find_by_name('Oauth2Manage').update_attributes(:privilege_tag_id => PrivilegeTag.find_by_name_tag('administration_operations').id, :priority=>193)
end


menu_link_present = MenuLink rescue false
unless menu_link_present == false
  administration_category = MenuLinkCategory.find_by_name("administration")
  MenuLink.create(:name=>'manage_clients',:target_controller=>'oauth_clients',:target_action=>'index',:higher_link_id=>MenuLink.find_by_name('settings').id,:icon_class=>nil,:link_type=>'general',:user_type=>nil,:menu_link_category_id=>administration_category.id) unless MenuLink.exists?(:name=>'manage_clients')

end