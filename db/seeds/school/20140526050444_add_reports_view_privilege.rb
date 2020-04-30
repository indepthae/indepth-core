unless Configuration.find_by_config_key("AdditionalReportsPrivilege").try(:config_value) == "1"
  Privilege.reset_column_information
  Privilege.find_or_create_by_name :name => 'ReportsView' , :description => 'reports_view_privilege'
  if Privilege.column_names.include?("privilege_tag_id")
    Privilege.find_by_name('ReportsView').update_attributes(:privilege_tag_id=>PrivilegeTag.find_by_name_tag('academics').id, :priority=> 321 )
  end
  Configuration.create(:config_key => "AdditionalReportsPrivilege",:config_value => "1")
end