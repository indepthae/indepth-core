administration_menu_link_category = MenuLinkCategory.find_by_name('administration')
if administration_menu_link_category.present? and !administration_menu_link_category.allowed_roles.include?(:students_control)
  administration_menu_link_category.allowed_roles << :students_control 
  administration_menu_link_category.save
end