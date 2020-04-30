cat = MenuLinkCategory.find_by_name("academics")
unless cat.nil?
  MenuLink.create(:name=>'student_records',:target_controller=>'student_records',:target_action=>'index',:higher_link_id=>nil,:icon_class=>'student_records-icon',:link_type=>'general',:user_type=>nil,:menu_link_category_id=>cat.id) unless MenuLink.exists?(:name=>'student_records')
end
