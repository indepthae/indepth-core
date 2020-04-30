timetable_menu = MenuLink.find_by_name('timetable_text')
if timetable_menu.present?
  old_menu_links = ['create_timetable','edit_timetable']
  MenuLink.find_all_by_name(old_menu_links).map(&:destroy) # destroy older menu links from timetable
  new_links = [{ :name => 'manage_subject', :target_controller => 'subjects', :target_action => 'index', :higher_link_id => timetable_menu.id, :link_type => 'general',:menu_link_category_id => timetable_menu.menu_link_category_id },
     { :name => 'manage_timetables', :target_controller => 'timetable', :target_action => 'manage_timetables', :higher_link_id => timetable_menu.id, :link_type => 'general', :menu_link_category_id => timetable_menu.menu_link_category_id }]
  new_links.each do |link|
    menu = MenuLink.find_by_name_and_higher_link_id(link[:name],link[:higher_link_id])
    MenuLink.create(link) unless menu.present?
  end
end