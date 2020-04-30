cat = MenuLinkCategory.find_by_name("administration")
unless cat.nil?
  higher_link = MenuLink.find_by_name_and_target_controller("settings", "configuration")
  MenuLink.create(:name => 'custom_words_text', :target_controller => 'custom_words', :target_action => 'index', :higher_link_id => higher_link.id, 
    :icon_class => nil, :link_type => 'general', :user_type => nil, :menu_link_category_id => cat.id) if higher_link.present?
end