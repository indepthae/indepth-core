category = MenuLinkCategory.find_by_name("collaboration")
MenuLink.create(:name=>'user_groups',:target_controller=>'user_groups',:target_action=>'index',:higher_link_id=>nil,:icon_class=>nil,:link_type=>'general',:user_type=>nil,:menu_link_category_id=>category.id) unless MenuLink.exists?(:name=>'user_groups') 
