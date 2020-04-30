privilege_tag=PrivilegeTag.find_by_name_tag("academics")
Privilege.find_or_create_by_name :name => "ManageGradebook", :description => "manage_gradebook_privilege", :privilege_tag_id => privilege_tag.id, :priority => 800
Privilege.find_or_create_by_name :name => "GradebookMarkEntry", :description => "gradebook_mark_entry_privilege", :privilege_tag_id => privilege_tag.id, :priority => 801
