Privilege.reset_column_information
Privilege.find_or_create_by_name :name => "SendEmail",:description => "send_email_privilege"
Privilege.find_or_create_by_name :name => "EmailAlertSettings",:description => "email_alert_settings_privilege"

menu_link_present = MenuLink rescue false
unless menu_link_present == false
  collaboration_category = MenuLinkCategory.find_by_name("collaboration")
  MenuLink.create(:name=>'email',:target_controller=>'email_alerts',:target_action=>'index',:higher_link_id=>nil,:icon_class=>'email-icon',:link_type=>'general',:user_type=>nil,:menu_link_category_id=>collaboration_category.id) unless MenuLink.exists?(:name=>'email')
end

if Privilege.column_names.include?("privilege_tag_id")
  Privilege.find_by_name('SendEmail').update_attributes(:privilege_tag_id=>PrivilegeTag.find_by_name_tag('system_settings').id, :priority=>361)
  Privilege.find_by_name('EmailAlertSettings').update_attributes(:privilege_tag_id=>PrivilegeTag.find_by_name_tag('system_settings').id, :priority=>362)
end