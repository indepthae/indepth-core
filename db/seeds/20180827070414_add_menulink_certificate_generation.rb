academics_category = MenuLinkCategory.find_by_name("academics")
unless academics_category.nil?
  menu_link = MenuLink.find_or_create_by_name(:name=>'certificates',:target_controller=>'certificate_templates',:target_action=>'index',:higher_link_id=>nil,:icon_class=>'certificate_templates-icon',
    :link_type=>'general',:user_type=>nil,:menu_link_category_id=>academics_category.id)

  MenuLink.find_or_create_by_name_and_higher_link_id(:name => "certificate_templates", :target_controller => "certificate_templates", :target_action => "certificate_templates",
    :icon_class => "certificate_templates-icon", :link_type => "general", :menu_link_category_id => academics_category.id, :higher_link_id => menu_link.id)

  MenuLink.find_or_create_by_name_and_higher_link_id(:name => "generate_individual_certificates", :target_controller => "certificate_templates", :target_action => "generate_certificate",
    :icon_class => "certificate_templates-icon", :link_type => "general", :menu_link_category_id => academics_category.id, :higher_link_id => menu_link.id)

  MenuLink.find_or_create_by_name_and_higher_link_id(:name => "generated_certificates", :target_controller => "certificate_templates", :target_action => "generated_certificates",
    :icon_class => "certificate_templates-icon", :link_type => "general", :menu_link_category_id => academics_category.id, :higher_link_id => menu_link.id)

  MenuLink.find_or_create_by_name_and_higher_link_id(:name => "bulk_generate_certificates", :target_controller => "certificate_templates", :target_action => "bulk_export",
    :icon_class => "certificate_templates-icon", :link_type => "general", :menu_link_category_id => academics_category.id, :higher_link_id => menu_link.id)
    
end
