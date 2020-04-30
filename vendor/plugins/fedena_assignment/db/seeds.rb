
menu_link_present = MenuLink rescue false
unless menu_link_present == false
  academics_category = MenuLinkCategory.find_by_name("academics")
  MenuLink.create(:name=>'assignment_text',:target_controller=>'assignments',:target_action=>'index',:higher_link_id=>nil,:icon_class=>'assignments-icon',:link_type=>'general',:user_type=>nil,:menu_link_category_id=>academics_category.id) unless MenuLink.exists?(:name=>'assignment_text')
end
