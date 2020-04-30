authorization do

  role :applicant_registration do
    has_permission_on [:pin_groups],
      :to=> [
      :index,
      :new,
      :create,
      :edit,
      :update,
      :show,
      :deactivate_pin_number,
      :deactivate_pin_group,
      :search_ajax
    ]

    has_permission_on [:applicants_admin],:to => [:index]
    
    has_permission_on [:reports],:to => [:csv_reports]
    
    has_permission_on [:applicants_admins],:to=>[:applicants_pdf,
      :show,:applicants,:view_applicant,
      :allot,:mark_paid,:mark_academically_cleared,:search_by_registration,:search_by_registration_pdf,:admit_applicant,:allot_applicant,:customize_form,
      :show_activating_form,:show_inactivating_form,:add_course,:registration_settings,:archive_all_applicants,:save_instruction,:new_status,:edit_status,:delete_status,
      :add_section,:create_section,:edit_section,:update_section,:delete_section,:add_field,:create_field,:link_student_additional_fields,:edit_field,:update_field,
      :delete_field,:create_attachment_field,:update_attachment_field,:preview_form,:show_course_instructions,:show_form,:filter_applicants,:update_status,:allot_applicants,
      :discard_applicants,:archived_applicants,:filter_archived_applicants,:discard_applicant,:update_applicant_status,:allocate_applicant,:edit_applicant,:update_applicant,
      :print_applicant_pdf,:generate_fee_receipt_pdf,:print_application_form,:fee_collection_list,:message_applicants,:detailed_csv_report
    ]
    has_permission_on [:applicant_additional_fields],:to=>[
      :index,:new,:create,:show,:edit,:update,:destroy,:toggle,:toggle_field,:change_order,:view_addl_docs,:download,:delete_doc]
    has_permission_on [:registration_courses],:to=>[
      :index,:show,:new,:edit,:create,:update,:destroy,:toggle,:amount_load,:settings_load,:populate_additional_field_list,:registration_settings,:archive_all_applicants,
      :customize_form,:add_section,:create_section,:edit_section,:update_section,:delete_section,:add_field,:create_field,:link_student_additional_fields,:edit_field,:update_field,
      :delete_field,:create_attachment_field,:update_attachment_field,:restore_defaults
    ]
  end

  role :addl_docs_view do
    has_permission_on [:applicant_additional_fields],:to=>[
      :view_addl_docs,
      :download
    ]
  end

  role :student_view do
    includes :addl_docs_view
  end

  role :manage_users do
    has_permission_on [:applicant_additional_fields],:to=>[
      :view_addl_docs,
      :download,
      :delete_doc
    ]
  end

  role :admission do
    has_permission_on [:applicant_additional_fields],:to=>[
      :view_addl_docs,
      :download,
      :delete_doc
    ]
  end
  role :finance_reports do
    has_permission_on [:applicants],:to=>[
       :applicant_registration_report_csv
    ]
  end
  role :miscellaneous do
    has_permission_on [:applicants],:to=>[
      :applicant_registration_report_csv
    ]
  end
  role :students_control do
    has_permission_on [:applicant_additional_fields],:to=>[
      :view_addl_docs,
      :download,
      :delete_doc
    ]
  end

  role :employee do
    includes :addl_docs_view
  end

  role :parent do
    includes :addl_docs_view
  end

  role :admin do
    includes :applicant_registration
  end

  role :student do
    includes :addl_docs_view
  end

  role :guest do
    has_permission_on [:applicants],:to=>[:new,:create,:complete,:show_course_instructions,:show_form,:print_application,:show_pin_entry_form]
  end

end