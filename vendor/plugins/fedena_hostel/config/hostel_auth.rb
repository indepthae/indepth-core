authorization do

  role :students_control do
    includes :fee_view
  end
  role :student_view do
    includes :fee_view
    includes :hostel_view
  end

  role :hostel_admin do
    has_permission_on [:hostels],
      :to=>[
      :index,
      :new,
      :create,
      :edit,
      :update,
      :show,
      :destroy,
      :update_employees,
      :hostel_dashboard,
      :student_hostel_details,
      :room_delete,
      :room_availability_details,
      :room_availability_details_csv,
      :room_list,
      :room_list_csv,
      :individual_room_details,
      :sort_by,
      :add_additional_details,
      :change_field_priority,
      :edit_additional_details,
      :delete_additional_details
    ]
    has_permission_on [:finance],
      :to=>[
      :generate_fee_receipt_pdf
    ]
    has_permission_on [:report],
      :to=>[
      :csv_reports,
      :csv_report_download
    ]
    has_permission_on [:hostel_fee],
      :to=>[
      :hostel_fee_collection,
      :hostel_fee_collection_new,
      :hostel_fee_collection_edit,
      :update_hostel_fee_collection_date,
      :hostel_fee_collection_create,
      :hostel_fee_collection_view,
      :batchwise_collection_dates,
      :hostel_fee_pay,
      :update_fee_collection_dates,
      :hostel_fee_collection_details,
      :pay_fees,
      :hostel_fee_defaulters,
      :update_fee_collection_defaulters_dates,
      :hostel_fee_collection_defaulters_details,
      :pay_defaulters_fees,
      :index,
      :search_ajax,
      :student_hostel_fee,
      :fees_submission_student,
      :hostel_fee_collection_pay,
      :student_fee_receipt_pdf,
      :delete_fee_collection_date,
      :hostel_fees_report,
      :course_wise_hostel_fee_collection,
      :batch_hostel_fees_report,
      :hostel_fee_submission_student,
      :update_student_fine_ajax,
      :select_payment_mode,
      :student_profile_fee_details,
      :delete_hostel_fee_transaction,
      :student_wise_fee_collection_new,
      :search_student,
      :allocate_or_deallocate_fee_collection,
      :list_students_by_batch,
      :list_fees_for_student,
      :list_fee_collections_for_student,
      :collection_creation_and_assign,
      :update_fees_collections,
      :render_collection_assign_form,
      :collection_assign_students,
      :list_students_for_collection,
      :choose_collection_and_assign
    ]
    has_permission_on [:room_details],
      :to=>[
      :index,
      :update_room_list,
      :new,
      :create,
      :destroy,
      :edit,
      :update,
      :show,
      :sort_by,
      :add_additional_details,
      :change_field_priority,
      :edit_additional_details,
      :delete_additional_details
    ]
    has_permission_on [:room_allocate],
      :to=>[
      :index,
      :search_ajax,
      :assign_room,
      :room_details,
      :allocate,
      :vacate,
      :change_room,
      :change_room_details,
      :relocate  ]
    has_permission_on [:wardens],
      :to =>[
      :index,
      :new,
      :create,
      :update_employees,
      :destroy
    ]
  end

  role :fee_view do
    has_permission_on [:hostel_fee],
      :to=>[
      :student_profile_fee_details,
    ]
  end
  role :hostel_view do
    has_permission_on [:hostels],
      :to=>[
      :student_hostel_details,
    ]
  end

  role :admin do
    includes :hostel_admin
  end

  role :manage_users do
    has_permission_on [:hostels],
      :to=>[
      :student_hostel_details ]
  end

  role :students_control do
    has_permission_on [:hostels],
      :to => [:student_hostel_details]
  end

  role :student do
    has_permission_on [:hostels],
      :to=>[
      :student_hostel_details ]

    has_permission_on [:hostel_fee],
      :to=>[
      :student_profile_fee_details
    ]do
      if_attribute :user =>{:id=> is {user.id}}
    end
    has_permission_on [:hostel_fee],
      :to=>[
      :student_fee_receipt_pdf
    ]do
      if_attribute :student_id => is {user.student_record.id}
    end
  end


  role :parent do
    has_permission_on [:hostels],
      :to=>[
      :student_hostel_details 
    ],:join_by=> :and do 
      if_attribute :assess_truth  => is {user.hostel_access?}
      if_attribute :id => is {user.parent_record.id}
    end
    has_permission_on [:hostel_fee],
      :to=>[
      :student_profile_fee_details
    ]do
      if_attribute :user =>{:id=> is {user.parent_record.user_id}}
    end
    has_permission_on [:hostel_fee],
      :to=>[
      :student_fee_receipt_pdf
    ]do
      if_attribute :student_id => is {user.parent_record.id}
    end
  end

  role :finance_reports do
    has_permission_on [:hostel_fee],
      :to => [:hostel_fees_report,
      :hostel_fees_report_csv,
      :course_wise_hostel_fee_collection,
      :course_wise_hostel_fee_collection_csv,
      :batch_hostel_fees_report,
      :batch_hostel_fees_report_csv,
      :show_date_filter,
    ]
  end

end
