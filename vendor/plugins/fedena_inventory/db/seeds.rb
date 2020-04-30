Privilege.reset_column_information
Privilege.find_or_create_by_name(:name => "InventoryManager", :description=>"inventory_manager_privilege")
Privilege.find_or_create_by_name(:name => "Inventory", :description=>"inventory_privilege")
Privilege.find_or_create_by_name(:name => "InventoryBasics", :description=>"inventory_basics_privilege")
FinanceTransactionCategory.find_or_create_by_name(:name=>"Inventory",:is_income=>false,:description=>"Inventory Module")
if Privilege.column_names.include?("privilege_tag_id")
  Privilege.find_by_name('InventoryManager').update_attributes(:privilege_tag_id=>PrivilegeTag.find_by_name_tag('administration_operations').id, :priority=>190 )
  Privilege.find_by_name('Inventory').update_attributes(:privilege_tag_id=>PrivilegeTag.find_by_name_tag('administration_operations').id, :priority=>200 )
  Privilege.find_by_name('InventoryBasics').update_attributes(:privilege_tag_id=>PrivilegeTag.find_by_name_tag('administration_operations').id, :priority=>205 )
end

