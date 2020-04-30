cat = MenuLinkCategory.find_by_name("academics")
higher_link=MenuLink.find_by_name('remarks_text')
unless cat.nil?
  MenuLink.create(:name=>'add_custom_remarks',:target_controller=>'remarks',:target_action=>'add_employee_custom_remarks',:higher_link_id=>higher_link.id,:icon_class=>nil,:link_type=>'general',:user_type=>nil,:menu_link_category_id=>cat.id) unless MenuLink.exists?(:name=>'add_custom_remarks')
  MenuLink.create(:name=>'list_custom_remarks',:target_controller=>'remarks',:target_action=>'employee_list_custom_remarks',:higher_link_id=>higher_link.id,:icon_class=>nil,:link_type=>'general',:user_type=>nil,:menu_link_category_id=>cat.id) unless MenuLink.exists?(:name=>'list_custom_remarks')
end
