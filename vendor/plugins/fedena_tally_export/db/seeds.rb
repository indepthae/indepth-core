[
  {"config_key" => "TallyUrl"                 ,"config_value" => "" },
  {"config_key" => "EnableLiveSync"           ,"config_value" => "0"},
  {"config_key" => "LiveSyncStartDate"        ,"config_value" => ""}
].each do |param|
  TallyExportConfiguration.find_or_create_by_config_key(param)
end

menu_link_present = MenuLink rescue false
unless menu_link_present == false
  administration_category = MenuLinkCategory.find_by_name("administration")

  MenuLink.create(:name=>'tally_export_text',:target_controller=>'tally_exports',:target_action=>'index',:higher_link_id=>MenuLink.find_by_name('finance_text').id,:icon_class=>nil,:link_type=>'general',:user_type=>nil,:menu_link_category_id=>administration_category.id) unless MenuLink.exists?(:name=>'tally_export_text')
end