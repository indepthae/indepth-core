menu_link_present = MenuLink rescue false
unless menu_link_present == false
  reports_category = MenuLinkCategory.find_by_name("data_and_reports")
  MenuLink.create(:name=>'data_exports_text',:target_controller=>'data_exports',:target_action=>'index',:higher_link_id=>nil,:icon_class=>'export-icon',:link_type=>'general',:user_type=>nil,:menu_link_category_id=>reports_category.id) unless MenuLink.exists?(:name=>'data_exports_text')
end