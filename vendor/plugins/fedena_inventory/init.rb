# Include hook code here

require 'translator'
require File.join(File.dirname(__FILE__), "lib", "fedena_inventory")
require File.join(File.dirname(__FILE__), "config", "breadcrumbs")

FedenaPlugin.register = {
  :name=>"fedena_inventory",
  :description=>"Fedena Inventory Module",
  :auth_file=>"config/inventory_auth.rb",
  :more_menu=> {:title=>"inventory_text",:controller=>"inventories",:action=>"index",:target_id=>"more-parent"},
  :sub_menus=>[ {:title=>"store_category",:controller=>"store_categories",:action=>"index",:target_id=>"fedena_inventory"},
    {:title=>"store_type",:controller=>"store_types",:action=>"index",:target_id=>"fedena_inventory"},
    {:title=>"store",:controller=>"stores",:action=>"index",:target_id=>"fedena_inventory"},
    {:title=>"item_category",:controller=>"item_categories",:action=>"index",:target_id=>"fedena_inventory"},
    {:title=>"store_item",:controller=>"store_items",:action=>"index",:target_id=>"fedena_inventory"},
    {:title=>"supplier_type",:controller=>"supplier_types",:action=>"index",:target_id=>"fedena_inventory"},
    {:title=>"supplier",:controller=>"suppliers",:action=>"index",:target_id=>"fedena_inventory"},
    {:title=>"indent",:controller=>"indents",:action=>"index",:target_id=>"fedena_inventory"},
    {:title=>"purchase_order",:controller=>"purchase_orders",:action=>"index",:target_id=>"fedena_inventory"},
    {:title=>"billing",:controller=>"invoices",:action=>"index",:target_id=>"fedena_inventory"},
    {:title=>"grn",:controller=>"grns",:action=>"index",:target_id=>"fedena_inventory"},
    {:title=>"reports",:controller=>"inventory_reports",:action=>"index",:target_id=>"fedena_inventory"}],
  :multischool_models=>%w{GrnItem Grn IndentItem Indent PurchaseItem PurchaseOrder StoreCategory StoreItem Store StoreType Supplier SupplierType ItemCategory Invoice AdditionalCharge Discount SalesUserDetail SoldItem},
  :finance=>[{:category_name=>"Inventory",:is_income =>0,  :destination=>{:controller=>"grns" , :action => "report"},:plugin_name=>"fedena_inventory"},
            {:category_name=>"SalesInventory",:is_income =>1,  :destination=>{:controller=>"invoices" , :action => "report"},:plugin_name=>"fedena_inventory"}]
  
}

FedenaInventory.attach_overrides

Dir[File.join("#{File.dirname(__FILE__)}/config/locales/*.yml")].each do |locale|
  I18n.load_path.unshift(locale)
end

if RAILS_ENV == 'development'
  ActiveSupport::Dependencies.load_once_paths.reject!{|x| x =~ /^#{Regexp.escape(File.dirname(__FILE__))}/}
end



