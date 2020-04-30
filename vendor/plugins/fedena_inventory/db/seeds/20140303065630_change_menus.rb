# finds menu link with name having space in it and if found will destroy them
purchase_order = MenuLink.find_by_name('purchase order')
if purchase_order.present?
  purchase_order.destroy
end

supplier_type = MenuLink.find_by_name('supplier type')
if supplier_type.present?
  supplier_type.destroy
end