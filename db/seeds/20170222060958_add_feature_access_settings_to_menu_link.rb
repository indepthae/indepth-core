cat = MenuLinkCategory.find_by_name("administration")
unless cat.nil?
  higher_link = MenuLink.find_by_name("settings")
  MenuLink.create(:name=>'feature_access_settings',:target_controller=>'feature_access_settings',:target_action=>'index',:higher_link_id=>higher_link.id,:icon_class=>nil,:link_type=>'general',:user_type=>nil,:menu_link_category_id=>cat.id) if MenuLink.exists?(:name=>'settings')
end