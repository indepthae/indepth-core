# To change this template, choose Tools | Templates
# and open the template in the editor.
MenuLinkCategory.reset_column_information
unless MenuLinkCategory.exists?(:name=>"apps")
  MenuLinkCategory.create(:name=>"apps",:allowed_roles=>[:admin,:employee,:student,:parent],:origin_name=>"fedena_app_frame")
end
Privilege.reset_column_information
Privilege.find_or_create_by_name(:name => "AppFrameAdmin", :description=>"app_frame_admin_privilege")
if Privilege.column_names.include?("privilege_tag_id")
  Privilege.find_by_name('AppFrameAdmin').update_attributes(:privilege_tag_id => PrivilegeTag.find_by_name_tag('administration_operations').id, :priority=>191 )
end
