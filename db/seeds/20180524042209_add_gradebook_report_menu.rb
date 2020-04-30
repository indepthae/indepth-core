academics_category = MenuLinkCategory.find_by_name("academics")
unless academics_category.nil?
  menu_link = MenuLink.find_or_create_by_name(:name => "gradebook", :target_controller => "gradebooks",
    :target_action => "index", :icon_class => "examination-icon", :link_type => "general", :menu_link_category_id => academics_category.id)
  MenuLink.find_or_create_by_name_and_higher_link_id(:name => "gradebook_reports", :target_controller => "gradebook_reports", :target_action => "index", 
    :icon_class => "examination-icon", :link_type => "general", :menu_link_category_id => academics_category.id, :higher_link_id => menu_link.id)
end