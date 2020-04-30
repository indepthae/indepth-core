Privilege.reset_column_information
Privilege.find_or_create_by_name :name => 'ManageBuilding' , :description => 'manage_building_privilege'
if Privilege.column_names.include?("privilege_tag_id")
  Privilege.find_by_name('ManageBuilding').update_attributes(:privilege_tag_id=>PrivilegeTag.find_by_name_tag('academics').id, :priority=> 323 )
end

