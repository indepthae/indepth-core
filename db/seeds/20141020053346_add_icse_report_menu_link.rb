academics_category = MenuLinkCategory.find_by_name("academics")
if academics_category.present?
   MenuLink.find_or_create_by_name(:name=>'icse_reports',:target_controller=>'icse_reports',:target_action=>'index',:higher_link_id=>MenuLink.find_by_name('examination').id,:icon_class=>nil,:link_type=>'general',:user_type=>nil,:menu_link_category_id=>academics_category.id) unless MenuLink.exists?(:name=>'icse_reports')
end