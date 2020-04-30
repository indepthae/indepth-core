cat = MenuLinkCategory.find_by_name("academics")
unless cat.nil?
  menu_link_id = MenuLink.find_by_name("attendance").id
  MenuLink.create(:name=>'attendance_status',:target_controller=>'attendance_labels',:target_action=>'index',:higher_link_id=>menu_link_id,:icon_class=>'attendance-label-icon',:link_type=>'general',:user_type=>nil,:menu_link_category_id=>cat.id) unless MenuLink.exists?(:name=>'attendance_status')
end