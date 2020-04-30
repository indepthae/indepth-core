configuration_menu = MenuLink.find_by_name('settings')
if configuration_menu.present?
  student_document_category_link = {:name => 'student_document_manager', :target_controller => 'student_document_categories', :target_action => 'index', :higher_link_id => configuration_menu.id, :link_type => "general", :menu_link_category_id => configuration_menu.menu_link_category_id}
  menu = MenuLink.find_by_name_and_higher_link_id(student_document_category_link[:name],student_document_category_link[:higher_link_id])
  MenuLink.create(student_document_category_link)
end