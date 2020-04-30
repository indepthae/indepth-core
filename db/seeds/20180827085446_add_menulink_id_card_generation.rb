academics_category = MenuLinkCategory.find_by_name("academics")
unless academics_category.nil?
  menu_link = MenuLink.find_or_create_by_name(:name=>'id_cards',:target_controller=>'id_card_templates',:target_action=>'index',:higher_link_id=>nil,:icon_class=>'id_card_templates-icon',
    :link_type=>'general',:user_type=>nil,:menu_link_category_id=>academics_category.id)

  MenuLink.find_or_create_by_name_and_higher_link_id(:name => "id_card_templates", :target_controller => "id_card_templates", :target_action => "id_card_templates",
    :icon_class => "id_card_templates-icon", :link_type => "general", :menu_link_category_id => academics_category.id, :higher_link_id => menu_link.id)

  MenuLink.find_or_create_by_name_and_higher_link_id(:name => "generate_individual_id_card", :target_controller => "id_card_templates", :target_action => "generate_id_card",
    :icon_class => "id_card_templates-icon", :link_type => "general", :menu_link_category_id => academics_category.id, :higher_link_id => menu_link.id)

  MenuLink.find_or_create_by_name_and_higher_link_id(:name => "generated_id_cards", :target_controller => "id_card_templates", :target_action => "generated_id_cards",
    :icon_class => "id_card_templates-icon", :link_type => "general", :menu_link_category_id => academics_category.id, :higher_link_id => menu_link.id)

  MenuLink.find_or_create_by_name_and_higher_link_id(:name => "bulk_generate_id_cards", :target_controller => "id_card_templates", :target_action => "bulk_export",
    :icon_class => "id_card_templates-icon", :link_type => "general", :menu_link_category_id => academics_category.id, :higher_link_id => menu_link.id)
    
end
