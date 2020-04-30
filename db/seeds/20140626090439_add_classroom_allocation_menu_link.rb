cat = MenuLinkCategory.find_by_name("academics")
unless cat.nil?
  menu_link_id = MenuLink.find_by_name("timetable_text").id
  MenuLink.create(:name=>'classroom_allocation',:target_controller=>'classroom_allocations',:target_action=>'index',:higher_link_id=>menu_link_id,:icon_class=>'classroom_allocations-icon',:link_type=>'general',:user_type=>nil,:menu_link_category_id=>cat.id) unless MenuLink.exists?(:name=>'classroom_allocation')
end

