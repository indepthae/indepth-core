menu_link_category = MenuLinkCategory.find_by_name("administration")
if menu_link_category.present?
  sms_module_menu_link = menu_link_category.menu_links.first(:conditions=>["name='sms_module'"])
  if sms_module_menu_link.present?
    sms_module_menu_link.destroy
  else 
  end 
else
end