academics_category = MenuLinkCategory.find_by_name("academics")
unless academics_category.nil?
  menu_link = MenuLink.find_or_create_by_name(:name => "subjects_center_text", :target_controller => "subjects_center",
    :target_action => "index", :icon_class => "subjects-icon", :link_type => "general", :menu_link_category_id => academics_category.id)
  MenuLink.find_or_create_by_name_and_higher_link_id(:name => "course_subjects", :target_controller => "subjects_center", :target_action => "course_subjects", 
    :icon_class => "subjects-icon", :link_type => "general", :menu_link_category_id => academics_category.id, :higher_link_id => menu_link.id)
  MenuLink.find_or_create_by_name_and_higher_link_id(:name => "subject_skill_sets", :target_controller => "subject_skill_sets", :target_action => "index", 
    :icon_class => "subjects-icon", :link_type => "general", :menu_link_category_id => academics_category.id, :higher_link_id => menu_link.id)
  MenuLink.find_or_create_by_name_and_higher_link_id(:name => "link_batches", :target_controller => "subjects_center", :target_action => "link_batches", 
    :icon_class => "subjects-icon", :link_type => "general", :menu_link_category_id => academics_category.id, :higher_link_id => menu_link.id)
end