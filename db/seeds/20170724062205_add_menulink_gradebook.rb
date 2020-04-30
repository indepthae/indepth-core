academics_category = MenuLinkCategory.find_by_name("academics")
unless academics_category.nil?
  menu_link = MenuLink.find_or_create_by_name(:name => "gradebook", :target_controller => "gradebooks",
    :target_action => "index", :icon_class => "examination-icon", :link_type => "general", :menu_link_category_id => academics_category.id)

  MenuLink.find_or_create_by_name(:name => "exam_year_planner", :target_controller => "assessment_plans", :target_action => "index", 
    :icon_class => "examination-icon", :link_type => "general", :menu_link_category_id => academics_category.id, :higher_link_id => menu_link.id)

  MenuLink.find_or_create_by_name_and_higher_link_id(:name => "settings", :target_controller => "gradebooks", :target_action => "settings", 
    :icon_class => "examination-icon", :link_type => "general", :menu_link_category_id => academics_category.id, :higher_link_id => menu_link.id)
  
  MenuLink.find_or_create_by_name_and_higher_link_id(:name => "exam_management", :target_controller => "gradebooks", :target_action => "exam_management", 
    :icon_class => "examination-icon", :link_type => "general", :menu_link_category_id => academics_category.id, :higher_link_id => menu_link.id)
end

cat = MenuLinkCategory.find_by_name("administration")
unless cat.nil?
  higher_link = MenuLink.find_by_name_and_target_controller("settings", "configuration")
  MenuLink.create(:name => 'academic_years_text', :target_controller => 'academic_years', :target_action => 'index', :higher_link_id => higher_link.id, 
    :icon_class => nil, :link_type => 'general', :user_type => nil, :menu_link_category_id => cat.id) if higher_link.present?
end