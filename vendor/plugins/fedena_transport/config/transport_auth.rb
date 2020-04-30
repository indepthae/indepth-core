authorization do

  role :students_control do
    includes :fee_view
  end
  role :student_view do
    includes :fee_view
    includes :transport_view
  end
  #transport
  role :transport_admin do
    has_permission_on [:transport],
      :to=>[
      :index,
      :dash_board,
      :search_ajax,
      :transport_details,
      :ajax_transport_details,
      :add_transport,
      :update_vehicle,
      :load_fare,
      :seat_description,
      :delete_transport,
      :edit_transport,
      :student_transport_details,
      :employee_transport_details,
      :pdf_report,
      :vehicle_report,
      :vehicle_report_csv,
      :single_vehicle_details,
      :single_vehicle_details_csv,
      :reports,
      :student_transport_report,
      :students_transport_report_csv,
      :list_batches,
      :employee_transport_report,
      :employee_transport_report_csv,
      :route_report,
      :list_routes,
      :route_report_csv,
      :configurations,
      :settings,
      :show_batches,
      :show_passengers,
      :advanced_search,
      :assign_passenger,
      :show_stops,
      :unassign_passenger,
      :show_transport_form,
      :show_transport_mode,
      :fetch_stops,
      :calculate_fare,
      :send_notification,
      :load_stops_selector,
      :load_stop_recievers,
      :initiate_notification_send
    ]
    has_permission_on [:transport_passenger_imports],
      :to => [
      :index,
      :create,
      :download_structure,
      :show_import_log
    ]
    has_permission_on [:transport_reports],
      :to => [
      :index,
      :report,
      :show_batches,
      :passenger_type_search,
      :fetch_report,
      :fetch_columns,
      :show_date_range,
      :report_csv,
      :show_routes
    ]
    has_permission_on [:report],
      :to=>[
      :csv_reports,
      :csv_report_download
    ]
    has_permission_on [:transport_fee],
      :to=>[
      :index,
      :transport_fee_collections,
      :transport_fee_collection_new,
      :fine_list,
      :transport_fee_collection_create,
      :transport_fee_collection_view,
      :transport_fee_collection_details,
      :transport_fee_collection_edit,
      :transport_fee_collection_date_edit,
      :transport_fee_collection_date_update,
      :transport_fee_collection_update,
      :transport_fee_collection_delete,
      :delete_fee_collection_date,
      :transport_fee_pay,
      :transport_fee_defaulters_view,
      :transport_fee_defaulters_details,
      :transport_defaulters_fee_pay,
      :tsearch_logic,
      :fees_student_dates,
      :fees_employee_dates,
      :create_instant_discount,
      :delete_instant_discount,
      :update_fee_collection_dates,
      :fees_submission_student,
      :fees_submission_employee,
      :transport_fee_collection_pay,
      :transport_fee_collection_details,
      :defaulters_update_fee_collection_dates,
      :defaulters_update_fee_collection_details,
      :defaulters_transport_fee_collection_details,
      :employee_defaulters_transport_fee_collection,
      :employee_defaulters_transport_fee_collection_details,
      :transport_fee_search,
      :student_fee_receipt_pdf,
      :update_fine_ajax,
      :update_employee_fine_ajax,
      :update_student_fine_ajax,
      :update_employee_fine_ajax2,
      :update_defaulters_fine_ajax,
      :update_employee_defaulters_fine_ajax,
      :update_user_ajax,
      :update_batch_list_ajax,
      :update_fine_on_payment_date_change_ajax,
      :fees_submission_defaulter_student,
      :transport_fee_receipt_pdf,
      :transport_fees_report,
      :transport_student_course_wise_collection_report,
      :category_wise_collection_report,
      :batch_transport_fees_report,
      :employee_transport_fees_report,
      :select_payment_mode,
      :student_profile_fee_details,
      :delete_transport_transaction,
      :receiver_wise_collection_new,
      :search_student,
      :receiver_wise_fee_collection_creation,
      :allocate_or_deallocate_fee_collection,
      :list_students_by_batch,
      :list_fees_for_student,
      :list_students_for_collection,
      :list_fee_collections_for_employees,
      :list_employees_by_department,
      :list_fees_for_employee,
      :collection_creation_and_assign,
      :choose_collection_and_assign,
      :update_fees_collections,
      :render_collection_assign_form,
      :collection_assign_students,
      :show_employee_departments,
      :show_student_batches,
      :pay_transport_fees,
      :pay_batch_wise,
      :fetch_waiver_amount_transport_fee

    ]
    has_permission_on [:routes],
      :to=>[
      :index,
      :new,
      :create,
      :edit,
      :update,
      :delete_route,
      :show,
      :sort_by,
      :add_additional_details,
      :change_field_priority,
      :edit_additional_details,
      :delete_additional_details,
      :reorder_stops,
      :save_order,
      :route_details_csv,
      :activate_route,
      :inactivate_route
    ]
    has_permission_on [:vehicles],
      :to=>[
      :index,
      :new,
      :create,
      :edit,
      :update,
      :delete_vehicle,
      :show,
      :sort_by,
      :add_additional_details,
      :change_field_priority,
      :edit_additional_details,
      :delete_additional_details,
      :assign_passengers,
      :select_passenger,
      :list_batches_by_course,
      :list_students_by_batch,
      :list_employees_by_department,
      :check_passenger,
      :final_list_for_vehicle,
      :sort_passengers,
      :passengers_list
    ]
    has_permission_on [:finance],
      :to=>[
      :generate_fee_receipt_pdf,
      :generate_fee_receipt
    ]
    has_permission_on [:route_additional_details],
      :to=>[
      :index,
      :new,
      :create,
      :edit,
      :update,
      :delete_details,
      :change_field_priority
    ]
    has_permission_on [:vehicle_additional_details],
      :to=>[
      :index,
      :new,
      :create,
      :edit,
      :update,
      :delete_details,
      :change_field_priority
    ]
    has_permission_on [:vehicle_certificate_types],
      :to=>[
      :index,
      :new,
      :create,
      :edit,
      :update,
      :delete_certificate
    ]
    has_permission_on [:vehicle_stops],
      :to=>[
      :index,
      :new,
      :create,
      :edit,
      :update,
      :delete_stop,
      :activate_stop,
      :inactivate_stop
    ]
    has_permission_on [:vehicle_maintenances],
      :to=>[
      :index,
      :new,
      :create,
      :show,
      :edit,
      :update,
      :delete_record,
      :download_attachment
    ]
    has_permission_on [:vehicle_certificates],
      :to=>[
      :index,
      :new,
      :create,
      :edit,
      :update,
      :delete_certificate,
      :download
    ]
    has_permission_on [:transport_employees],
      :to=>[
      :index,
      :new,
      :create,
      :show_employees,
      :remove_employee
    ]
    has_permission_on [:transport_attendance],
      :to=>[
      :index,
      :create, 
      :search_passengers
    ]
    has_permission_on [:transport_imports],
      :to=>[
      :new,
      :create,
      :fetch_academic_years,
      :update_import_form,
      :show,
      :update
    ]
      has_permission_on [:transport_gps_settings],
        :to=>[
        :new,
        :create,
        :edit,
        :update,
        :index,
        :delete_gps_setting
        ]
        has_permission_on [:transport_gps_syncs],
        :to=>[
        :index,
        :sync_data
        ]
  end

  role :fee_view do
    has_permission_on [:transport_fee],
      :to=>[
      :student_profile_fee_details,
    ]
  end
  role :transport_view do
    has_permission_on [:transport],
      :to=>[
      :student_transport_details
    ]
  end
  role :admin do
    includes :transport_admin
  end

  role :manage_users do
    has_permission_on [:transport],
      :to=>[
      :student_transport_details,
      :employee_transport_details
    ]
  end
  role :employee_search do
    has_permission_on [:transport],
      :to=>[
      :employee_transport_details
    ]
  end
  role :hr_basics do
    has_permission_on [:transport],
      :to=>[
      :employee_transport_details
    ]
  end
  role :students_control do
    has_permission_on [:transport],
      :to => [:student_transport_details]
  end

  role :student do
    has_permission_on [:transport],
      :to=>[
      :student_transport_details
    ]
    has_permission_on [:transport_fee],
      :to=>[
      :student_profile_fee_details
    ]do
      if_attribute :user =>{:id=> is {user.id}}
    end
    has_permission_on [:transport_fee],
      :to=>[
      :transport_fee_receipt_pdf
    ],:join_by=> :and do
      if_attribute :payee_id => is {user.student_record.id}
      if_attribute :payee_type => 'Student'
    end
  end

  role :parent do
    has_permission_on [:transport],
      :to=>[
      :student_transport_details
    ],:join_by=> :and do 
      if_attribute :assess_truth  => is {user.transport_access?}
      if_attribute :id => is {user.parent_record.id}
    end
    has_permission_on [:transport_fee],
      :to=>[
      :student_profile_fee_details
    ]do
      if_attribute :user =>{:id=> is {user.parent_record.user_id}}
    end
    has_permission_on [:transport_fee],
      :to=>[
      :transport_fee_receipt_pdf
    ],:join_by=> :and do
      if_attribute :payee_id => is {user.parent_record.id}
      if_attribute :payee_type => 'Student'
    end
  end

  role :employee do
    has_permission_on [:transport],
      :to=>[
      :employee_transport_details
    ]do
      if_attribute :id => is {user.id}
    end
  end

  role :finance_reports do
    has_permission_on [:transport_fee],
      :to => [:transport_fees_report,
      :batch_transport_fees_report,
      :transport_fees_report_csv,
      :transport_employee_department_wise_collection_report_csv,
      :employee_transport_fees_report_csv,
      :show_date_filter,
      :category_wise_collection_report,
      :employee_transport_fees_report
    ]
  end

end
