Privilege.reset_column_information
Privilege.find_or_create_by_name :name => "Gallery",:description => 'gallery'
if Privilege.column_names.include?("privilege_tag_id")
  Privilege.find_by_name('Gallery').update_attributes(:privilege_tag_id=>PrivilegeTag.find_by_name_tag('social_other_activity').id, :priority=>370 )
end

menu_link_present = MenuLink rescue false
unless menu_link_present == false
  collaboration_category = MenuLinkCategory.find_by_name("collaboration")
  MenuLink.create(:name=>'gallery',:target_controller=>'galleries',:target_action=>'index',:higher_link_id=>nil,:icon_class=>'galleries-icon',:link_type=>'general',:user_type=>nil,:menu_link_category_id=>collaboration_category.id) unless MenuLink.exists?(:name=>'gallery')
end
