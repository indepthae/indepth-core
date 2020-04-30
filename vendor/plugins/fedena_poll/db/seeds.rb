Privilege.reset_column_information
Privilege.find_or_create_by_name :name =>"PollControl",:description => "poll_control_privilege"
if Privilege.column_names.include?("privilege_tag_id")
  Privilege.find_by_name('PollControl').update_attributes(:privilege_tag_id=>PrivilegeTag.find_by_name_tag('social_other_activity').id, :priority=>350 )
end

menu_link_present = MenuLink rescue false
unless menu_link_present == false
  collaboration_category = MenuLinkCategory.find_by_name("collaboration")
  MenuLink.create(:name=>'poll',:target_controller=>'poll_questions',:target_action=>'index',:higher_link_id=>nil,:icon_class=>'poll-icon',:link_type=>'general',:user_type=>nil,:menu_link_category_id=>collaboration_category.id) unless MenuLink.exists?(:name=>'poll')
end


