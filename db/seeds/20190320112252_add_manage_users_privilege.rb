privilege_tag=PrivilegeTag.find_by_name_tag("administration_operations")
Privilege.find_or_create_by_name :name => "ManageGroups", :description => "manage_groups_privilege", :privilege_tag_id => privilege_tag.id, :priority => 50
