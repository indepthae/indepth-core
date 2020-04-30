privilege_tag=PrivilegeTag.find_by_name_tag("academics")
Privilege.find_or_create_by_name :name => "CertificateManagement", :description => "certificate_management", :privilege_tag_id => privilege_tag.id, :priority => 810
Privilege.find_or_create_by_name :name => "IdCardManagement", :description => "id_card_management", :privilege_tag_id => privilege_tag.id, :priority => 811