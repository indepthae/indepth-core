Privilege.reset_column_information
Privilege.find_or_create_by_name :name => 'InventorySales' , :description => 'inventory_sales_privilege'
if Privilege.column_names.include?("privilege_tag_id")
  Privilege.find_by_name('InventorySales').update_attributes(:privilege_tag_id=>PrivilegeTag.find_by_name_tag('administration_operations').id, :priority=> 400 )
end
