cat = MenuLinkCategory.find_by_name("academics")
unless cat.nil?
  MenuLink.create(:name=>'remarks_text',:target_controller=>'remarks',:target_action=>'index',:higher_link_id=>nil,:icon_class=>'remarks-icon',:link_type=>'general',:user_type=>nil,:menu_link_category_id=>cat.id) unless MenuLink.exists?(:name=>'remarks_text')
end
