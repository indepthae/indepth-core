menu_link_present = MenuLink rescue false
unless menu_link_present == false
  administration_category = MenuLinkCategory.find_by_name("administration")

  MenuLink.create(:name=>'inventory_text',:target_controller=>'inventories',:target_action=>'index',:higher_link_id=>nil,:icon_class=>'inventory-icon',:link_type=>'general',:user_type=>nil,:menu_link_category_id=>administration_category.id) unless MenuLink.exists?(:name=>'inventory_text')

  higher_link=MenuLink.find_by_name('inventory_text')

  MenuLink.create(:name=>'store_category',:target_controller=>'store_categories',:target_action=>'index',:higher_link_id=>higher_link.id,:icon_class=>nil,:link_type=>'general',:user_type=>nil,:menu_link_category_id=>administration_category.id) unless MenuLink.exists?(:name=>'store_category')
  MenuLink.create(:name=>'store_type',:target_controller=>'store_types',:target_action=>'index',:higher_link_id=>higher_link.id,:icon_class=>nil,:link_type=>'general',:user_type=>nil,:menu_link_category_id=>administration_category.id) unless MenuLink.exists?(:name=>'store_type')
  MenuLink.create(:name=>'store',:target_controller=>'stores',:target_action=>'index',:higher_link_id=>higher_link.id,:icon_class=>nil,:link_type=>'general',:user_type=>nil,:menu_link_category_id=>administration_category.id) unless MenuLink.exists?(:name=>'store')
  MenuLink.create(:name=>'store_item',:target_controller=>'store_items',:target_action=>'index',:higher_link_id=>higher_link.id,:icon_class=>nil,:link_type=>'general',:user_type=>nil,:menu_link_category_id=>administration_category.id) unless MenuLink.exists?(:name=>'store_item')
  MenuLink.create(:name=>'supplier_type',:target_controller=>'supplier_types',:target_action=>'index',:higher_link_id=>higher_link.id,:icon_class=>nil,:link_type=>'general',:user_type=>nil,:menu_link_category_id=>administration_category.id) unless MenuLink.exists?(:name=>'supplier_type')
  MenuLink.create(:name=>'supplier',:target_controller=>'suppliers',:target_action=>'index',:higher_link_id=>higher_link.id,:icon_class=>nil,:link_type=>'general',:user_type=>nil,:menu_link_category_id=>administration_category.id) unless MenuLink.exists?(:name=>'supplier')
  MenuLink.create(:name=>'indent',:target_controller=>'indents',:target_action=>'index',:higher_link_id=>higher_link.id,:icon_class=>nil,:link_type=>'general',:user_type=>nil,:menu_link_category_id=>administration_category.id) unless MenuLink.exists?(:name=>'indent')
  MenuLink.create(:name=>'purchase_order',:target_controller=>'purchase_orders',:target_action=>'index',:higher_link_id=>higher_link.id,:icon_class=>nil,:link_type=>'general',:user_type=>nil,:menu_link_category_id=>administration_category.id) unless MenuLink.exists?(:name=>'purchase_order')
  MenuLink.create(:name=>'grn',:target_controller=>'grns',:target_action=>'index',:higher_link_id=>higher_link.id,:icon_class=>nil,:link_type=>'general',:user_type=>nil,:menu_link_category_id=>administration_category.id) unless MenuLink.exists?(:name=>'grn')
  MenuLink.create(:name=>'reports_text',:target_controller=>'inventories',:target_action=>'reports',:higher_link_id=>higher_link.id,:icon_class=>nil,:link_type=>'general',:user_type=>nil,:menu_link_category_id=>administration_category.id) unless MenuLink.exists?(:name=>'reports_text',:higher_link_id=>higher_link.id)
  MenuLink.create(:name=>'item_category',:target_controller=>'item_categories',:target_action=>'index',:higher_link_id=>higher_link.id,:icon_class=>nil,:link_type=>'general',:user_type=>nil,:menu_link_category_id=>administration_category.id) unless MenuLink.exists?(:name=>'item_category')
  MenuLink.create(:name=>'billing',:target_controller=>'invoices',:target_action=>'index',:higher_link_id=>higher_link.id,:icon_class=>nil,:link_type=>'general',:user_type=>nil,:menu_link_category_id=>administration_category.id) unless MenuLink.exists?(:name=>'billing')
end