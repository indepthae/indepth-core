ActionController::Routing::Routes.draw do |map|
  map.resources :custom_certificates, :collection=>{
    :add_new_field => [:get],
    :add_new_field_right => [:get],
    :show_demo_certificate => [:get,:post,:put],
    :generate_certificate => [:get,:post,:put],
    :select_batch => [:get,:post,:put],
    :select_students => [:get,:post,:put],
    :show_demo_view => [:get,:post,:put],
    :genrate_certificate_pdf => [:get,:post,:put]  
  }
  # map.resources :pre_student_registrations, :collection=>{:create_pre_student_registration => [:get,:post,:put]}
   map.resources :finance_settings, :collection=>{:single_statement_header_settings => [:get,:post], 
     :fee_general_settings => [:get,:post], :receipt_print_settings => [:get,:post,:put],
     :receipt_pdf_settings => [:get, :post], :fees_receipt_preview => [:get,:post]
     }
end