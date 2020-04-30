authorization do


  #Inventory module
  role :inventory do
    has_permission_on [:inventories],  :to => [:index,:search, :search_ajax,:select_sort_order,:indent_report_csv,:purchase_order_csv,:grn_report_csv,:taxable_discount_settings]
    has_permission_on [:store_categories],  :to => [:index, :edit, :destroy, :new, :create, :update]
    has_permission_on [:store_types],  :to => [:index, :edit, :destroy, :new, :create, :update]
    has_permission_on [:stores],  :to => [:index, :stores_pdf, :edit, :destroy,:new, :create, :update]
    has_permission_on [:store_items],  :to => [:index,:store_items_pdf, :edit, :destroy, :new, :create, :update, :search_ajax]
    has_permission_on [:supplier_types],  :to => [:index, :edit, :destroy, :show, :new, :create, :update]
    has_permission_on [:suppliers],  :to => [:suppliers_pdf,:index, :edit, :destroy, :show, :new, :create, :update]
    has_permission_on [:indents],  :to => [:search_items,:index, :edit, :destroy, :show, :new, :create, :update, :acceptance,  :update_item, :indent_pdf,:update_storeitem]
    has_permission_on [:purchase_orders],  :to => [:index, :edit, :destroy, :show, :new, :create, :update, :po_pdf,:update_supplier, :acceptance,:update_store,:update_item,:raised_grns]
    has_permission_on [:grns],  :to => [:index, :destroy, :show, :new, :create,:grn_pdf,:update_po, :report, :report_detail]
    has_permission_on [:item_categories], :to => [:index, :edit, :create, :update, :new, :destroy, :show]
    has_permission_on [:inventory_reports], :to => [:index, :reports]
    includes :inventory_sales
  end

  role :admin_inventory do
    has_permission_on [:inventories],  :to => [:index,:search, :search_ajax,:select_sort_order,:indent_report_csv,:purchase_order_csv,:grn_report_csv,:taxable_discount_settings]
    has_permission_on [:store_categories],  :to => [:index, :edit, :destroy, :new, :create, :update]
    has_permission_on [:store_types],  :to => [:index, :edit, :destroy, :new, :create, :update]
    has_permission_on [:stores],  :to => [:index, :stores_pdf, :edit, :destroy,:new, :create, :update]
    has_permission_on [:store_items],  :to => [:index,:store_items_pdf, :edit, :destroy, :new, :create, :update, :search_ajax]
    has_permission_on [:supplier_types],  :to => [:index, :edit, :destroy, :show, :new, :create, :update]
    has_permission_on [:suppliers],  :to => [:suppliers_pdf,:index, :edit, :destroy, :show, :new, :create, :update]
    has_permission_on [:indents],  :to => [:search_items,:index,:new,:create,:edit, :destroy, :show, :update, :acceptance,  :update_item, :indent_pdf,:update_storeitem]
    has_permission_on [:purchase_orders],  :to => [:index, :edit, :destroy, :show, :new, :create, :update, :po_pdf,:update_supplier, :acceptance,:update_store,:update_item,:raised_grns]
    has_permission_on [:grns],  :to => [:index, :destroy, :show, :new, :create,:grn_pdf,:update_po, :report, :report_detail]
    has_permission_on [:item_categories], :to => [:index, :edit, :create, :update, :new, :destroy, :show]
    has_permission_on [:inventory_reports], :to => [:index, :reports]
    includes :inventory_sales
  end

  role :admin do
    includes :admin_inventory
  end


  role :inventory_manager do
    has_permission_on [:indents],  :to => [:search_items, :index, :edit, :destroy, :show, :new, :create, :update, :acceptance,:set_manager, :update_item, :indent_pdf,:update_storeitem ]
    has_permission_on [:purchase_orders],  :to => [:index, :edit, :destroy, :show, :new, :create, :update,:po_pdf,:update_supplier, :acceptance,:update_store,:update_item,:raised_grns]
    has_permission_on [:store_items],  :to => [:index,:store_items_pdf, :edit, :destroy, :show, :new, :create, :update, :search_ajax]
    has_permission_on [:inventories],  :to => [:index ,:search, :search_ajax,:select_sort_order]
    has_permission_on [:inventory_reports], :to => [:index, :reports]
  end


  role :inventory_basics do
    has_permission_on [:indents],  :to => [:search_items,:index, :edit, :destroy, :show, :new, :create, :update, :set_manager, :update_item, :indent_pdf,:update_storeitem,:acceptance]
    has_permission_on [:store_items],  :to => [:index, :store_items_pdf, :search_ajax]
    has_permission_on [:inventories],  :to => [:index]
  end

  role :inventory_sales do
    has_permission_on [:inventory_reports], :to => [:invoice_report,:day_wise_report,:select_store_item,:index,:update_item_wise_report, :item_wise_report, :sales_reports]
    has_permission_on [:invoices], :to => [:report,:find_item_name,:index, :create,:new, :find_invoice_prefix, :show, :invoice_pdf, :update_invoice,:search_user_details,:search_username, :search_store_item, :search_code]
    has_permission_on [:inventories],  :to => [:index]
    has_permission_on [:invoices], :to => [ :edit, :update, :destroy ] do
      if_attribute :is_paid? => is {true}
    end
  end

  role :finance_reports do
    has_permission_on [:invoices],
      :to => [:report,:report_csv,:sold_items_report,:sold_items_report_csv,:sold_item_transactions,:sold_item_transactions_csv,:show_date_filter,:show,:invoice_pdf,:grn_pdf]
    has_permission_on [:grns],
      :to => [:report,:store_report_csv,:report_csv,:list_grn,:list_grn_csv,:show_date_filter,:report_detail,:grn_pdf]
  end
  
end

