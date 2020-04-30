cat = MenuLinkCategory.find_by_name("administration")
unless cat.nil?
  higher_link=MenuLink.find_or_create_by_name_and_higher_link_id(:name=>'settings',:higher_link_id=>nil)
  MenuLink.create(:name=>'manage_student_roll_number',:target_controller=>'student_roll_number',:target_action=>'index',:higher_link_id=>higher_link.id,:icon_class=>'student_roll_number-icon',:link_type=>'general',:user_type=>nil,:menu_link_category_id=>cat.id) unless MenuLink.exists?(:name=>'manage_student_roll_number')
  a = cat.allowed_roles
  a.push([:manage_roll_number])
  a.flatten!
  cat.allowed_roles = a.uniq
  cat.save
end
