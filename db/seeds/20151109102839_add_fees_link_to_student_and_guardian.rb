cat = MenuLinkCategory.find_by_name("academics")
unless cat.nil?
  MenuLink.create(:name=>'fees_text',:target_controller=>'student',:target_action=>'fees',:higher_link_id=>nil,:icon_class=>'finance-icon',:link_type=>'own',:user_type=>'student',:menu_link_category_id=>cat.id) unless MenuLink.exists?(:name=>'fees_text',:user_type=>'student')
end
