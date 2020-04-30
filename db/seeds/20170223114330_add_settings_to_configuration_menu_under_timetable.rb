timetable_menu = MenuLink.find_by_name('timetable_text')
if timetable_menu.present?
  setting_link = { :name => 'timetable_settings_text', :target_controller => 'timetable', :target_action => 'settings', :higher_link_id => timetable_menu.id, :link_type => 'general',:menu_link_category_id => timetable_menu.menu_link_category_id }
  menu = MenuLink.find_by_name_and_higher_link_id(setting_link[:name],setting_link[:higher_link_id])
  MenuLink.create(setting_link) unless menu.present?
end