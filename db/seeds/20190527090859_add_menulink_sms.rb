collaboration_category = MenuLinkCategory.find_by_name("collaboration")

unless collaboration_category.nil?
  menu_link = MenuLink.find_or_create_by_name(:name => "sms_text", :target_controller => "sms",
    :target_action => "index", :icon_class => "sms-icon", :link_type => "general", :menu_link_category_id => collaboration_category.id)

  MenuLink.find_or_create_by_name(:name => "settings", :target_controller => "sms", :target_action => "settings", 
    :icon_class => "sms-icon", :link_type => "general", :menu_link_category_id => collaboration_category.id, :higher_link_id => menu_link.id)
  
  MenuLink.find_or_create_by_name(:name => "send_sms", :target_controller => "sms", :target_action => "send_sms", 
    :icon_class => "sms-icon", :link_type => "general", :menu_link_category_id => collaboration_category.id, :higher_link_id => menu_link.id)
    
  MenuLink.find_or_create_by_name(:name => "birthday_sms", :target_controller => "sms", :target_action => "birthday_sms", 
    :icon_class => "sms-icon", :link_type => "general", :menu_link_category_id => collaboration_category.id, :higher_link_id => menu_link.id)
  
  MenuLink.find_or_create_by_name(:name => "message_templates", :target_controller => "message_templates", :target_action => "message_templates", 
    :icon_class => "sms-icon", :link_type => "general", :menu_link_category_id => collaboration_category.id, :higher_link_id => menu_link.id)
    
  MenuLink.find_or_create_by_name(:name => "sms_logs", :target_controller => "sms", :target_action => "show_sms_messages", 
    :icon_class => "sms-icon", :link_type => "general", :menu_link_category_id => collaboration_category.id, :higher_link_id => menu_link.id)
    
end
