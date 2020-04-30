cat = MenuLinkCategory.find_by_name("data_and_reports")
unless cat.nil?
  higher_link = MenuLink.find_by_name_and_target_controller("reports_text","report")
  if higher_link.present?
    MenuLink.create(:name=>'siblings_report',:target_controller=>'report',:target_action=>'siblings_report',:higher_link_id=>higher_link.id,:icon_class=>nil,:link_type=>'general',:user_type=>nil,:menu_link_category_id=>cat.id) unless MenuLink.exists?(:name=>"siblings_report")
  end
end