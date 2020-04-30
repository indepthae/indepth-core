ActionController::Routing::Routes.draw do |map|
  map.resources :store_categories
  map.resources :item_categories
  map.resources :store_types
  map.resources :stores, :collection => {:stores_pdf => [:get]}
  map.resources :store_items,:collection => {:store_items_pdf => [:get],:search_ajax => [:get,:post],:index => [:get,:post]}
  map.resources :supplier_types
  map.resources :suppliers, :collection => {:suppliers_pdf => [:get]}
  map.resources :inventories, :collection => {:search => [:get],:search_ajax => [:get,:post],:select_sort_order=>[:get],:indent_report_csv=>[:get],:purchase_order_csv=>[:get],:grn_report_csv=>[:get]}
  map.resources :indents,:member => {:indent_pdf => [:get],:acceptance => [:get,:post]}, :collection => {:search_items => :get}
  map.resources :purchase_orders, :member => { :acceptance => [:get,:post],:po_pdf => [:get],:raised_grns => [:get] }
  map.resources :grns,:member => {:grn_pdf => [:get]},:collection => {:report => [:get],:store_report_csv=>[:get],:list_grn_csv=>[:get]}
  map.resources :gins
  map.resources :invoices, :collection => {:report => [:get],:report_csv=>[:get],:sold_items_report_csv=>[:get],:sold_item_transactions_csv=>[:get],:invoice_pdf => [:get],:find_invoice_prefix => [:get],:search_code => [:get],:search_store_item => [:get], :search_username => [:get],:search_user_details => [:get], :find_item_name => [:get]}
  map.resources :inventory_reports,:collection => {:invoice_report => [:get],:day_wise_report => [:get],:select_store_item => [:get],:reports=>[:get], :update_item_wise_report => [:get],:sales_reports=> [:get], :item_wise_report=> [:get], :invoice_report=> [:get], :sales_report => [:get]}
end
