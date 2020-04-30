Privilege.reset_column_information
Privilege.find_or_create_by_name :name => "Discipline",:description=>"discipline_privilege"
if Privilege.column_names.include?("privilege_tag_id")
  Privilege.find_by_name('Discipline').update_attributes(:privilege_tag_id=>PrivilegeTag.find_by_name_tag('administration_operations').id, :priority=> 120 )
end


menu_link_present = MenuLink rescue false
unless menu_link_present == false
  academics_category = MenuLinkCategory.find_by_name("academics")
  MenuLink.create(:name=>'discipline',:target_controller=>'discipline_complaints',:target_action=>'index',:higher_link_id=>nil,:icon_class=>'discipline-icon',:link_type=>'general',:user_type=>nil,:menu_link_category_id=>academics_category.id) unless MenuLink.exists?(:name=>'discipline')
end