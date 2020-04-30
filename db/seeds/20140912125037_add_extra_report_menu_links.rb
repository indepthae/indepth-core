cat = MenuLinkCategory.find_by_name("data_and_reports")
unless cat.nil?

  higher_link=MenuLink.find_or_create_by_name_and_higher_link_id(:name=>'reports_text',:target_controller=>'report',:target_action=>'index',:higher_link_id=>nil,:icon_class=>'report-icon',:link_type=>'general',:user_type=>nil,:menu_link_category_id=>cat.id)

  MenuLink.create(:name=>'fees_head_wise_report',:target_controller=>'report',:target_action=>'fees_head_wise_report',:higher_link_id=>higher_link.id,:icon_class=>nil,:link_type=>'general',:user_type=>nil,:menu_link_category_id=>cat.id) unless MenuLink.exists?(:name=>'fees_head_wise_report')

end
