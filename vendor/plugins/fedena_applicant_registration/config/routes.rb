ActionController::Routing::Routes.draw do |map|
  map.resources :pin_groups,
    :member => {:deactivate_pin_group => [:get,:post],:deactivate_pin_number => [:get,:post]},
    :collection => {:search_ajax => [:get,:post]}
  map.resources :applicants,:collection=>{:applicant_registration_report_csv=>[:get],:show_course_instructions=>[:get],:show_form=>:get,:show_pin_entry_form => :get,:print_application => :get,:success => :get},
    :member=>{
    :preview_application=>[:get],
    :edit_application=>[:get],
    :update_application=>[:post],
    :generate_fee_receipt_pdf=>[:get],
    :submit_application=>[:get],
    :discard_application=>[:get]
    }
  
  map.resources :applicants_admins,:collection => {:view_applicant => :get,:courses=>:get,
    :allot=>:post,
    :search_by_registration => [:get,:post],
    :search_by_registration_pdf => :get,
    :show_activating_form => [:get,:post],
    :show_inactivating_form => [:get,:post],
    :registration_settings => [:get,:post],
    :archive_all_applicants => [:get,:post],
    :save_instruction => [:post],
    :new_status => [:get,:post],
    :customize_form => [:get,:post],
    :add_section => [:get],
    :create_section => [:get,:post],
    :add_field => [:get],
    :create_field => [:post],
    :create_attachment_field => [:post],
    :link_student_additional_fields => [:post],
    :add_course => [:get,:post],
    :preview_form => [:get],
    :show_course_instructions => [:get],
    :show_form => [:post],
    :filter_applicants => [:get],
    :filter_archived_applicants => [:get],
    :update_status => [:post],
    :allot_applicants => [:post],
    :discard_applicants => [:post],
    :fee_collection_list => [:get],
    :message_applicants => [:get,:post],
    :detailed_csv_report => [:get,:post]},
    
    :member=>{
    :applicants=>:get,
    :archived_applicants=>:get,
    :applicants_pdf => :get,
    :edit_status=>[:get,:post],
    :edit_section=>[:get,:post],
    :update_section=>[:get,:post],
    :edit_field=>[:get,:post],
    :update_field=>[:get,:post],
    :update_attachment_field=>[:post],
    :delete_field=>[:get],
    :delete_section=>[:get],
    :discard_applicant=>[:get],
    :view_applicant=>[:get],
    :print_applicant_pdf=>[:get],
    :generate_fee_receipt_pdf=>[:get],
    :print_application_form=>[:get],
    :edit_applicant=>[:get,:post],
    :update_applicant=>[:post],
    :update_applicant_status=>[:get,:post],
    :allocate_applicant=>[:get,:post],
    :delete_status=>[:get]
  }

  map.resource :applicants_admin
  
  map.resources :registration_courses,:member=>{
    :toggle=>:get,
    :registration_settings=>[:get,:post,:put],
    :archive_all_applicants=>[:get,:post],
    :customize_form => [:get,:post],
    :edit_section=>[:get,:post],
    :update_section=>[:get,:post],
    :edit_field=>[:get,:post],
    :update_field=>[:get,:post],
    :update_attachment_field=>[:post],
    :delete_field=>[:get],
    :restore_defaults=>[:get],
    :delete_section=>[:get]
  },
    :collection=>{
    :add_section => [:get],
    :create_section => [:get,:post],
    :add_field => [:get],
    :create_field => [:post],
    :create_attachment_field => [:post],
    :link_student_additional_fields => [:post]
  }
  
  #  map.resources :registration_courses,:member=>{:toggle=>:get,:registration_settings=>[:get,:post,:put],:archive_all_applicants=>[:get,:post]} do |m|
  #    m.resources :applicant_additional_fields,:member=>{:change_order=>:post,:toggle=>:get, :view_addl_docs => :get}
  #  end

  map.connect "/register", :controller => 'applicants', :action => 'new'
  map.connect "/register.:lang", :controller => 'applicants', :action => 'new'
end
