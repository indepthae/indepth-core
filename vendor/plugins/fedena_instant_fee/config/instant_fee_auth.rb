authorization do

  role :admin do
    has_permission_on [:instant_fees],
      :to=>[
      :index,
      :manage_fees,
      :new_category,
      :create_category,
      :edit_category,
      :update_category,
      :delete_category,
      :new_particular,
      :create_particular,
      :edit_particular,
      :update_particular,
      :delete_particular,
      :new_category_particular,
      :create_category_particular,
      :list_particulars,
      :new_instant_fees,
      :tsearch_logic,
      :category_type,
      :handle_category,
      :handle_category_for_guest,
      :create_instant_fee,
      :report,
      :show_date_filter,
      :instant_fee_report_csv,
      :instant_fee_report_detail_csv,
      :report_detail,
      :instant_fee_created_detail,
      :print_reciept,
      :select_payment_mode,
      :delete_transaction_for_instant_fee,
      :show_instant_fee_transactions,
      :list_instant_fee_transactions,
      :instant_fee_transaction_filter_by_date,
      :validate_transaction_date
    ]
  end

  role :manage_tax do
    has_permission_on [:instant_fees],
      :to => [:edit_particular_slab, :update_particular_slab]
  end
  
  role :manage_fee do
    has_permission_on [:instant_fees],
      :to=>[
      :index,
      :manage_fees,
      :new_category,
      :create_category,
      :edit_category,
      :update_category,
      :delete_category,
      :new_particular,
      :create_particular,
      :edit_particular,
      :update_particular,
      :delete_particular,
      :new_category_particular,
      :create_category_particular,
      :list_particulars,
      :create_instant_fee,
      :report,
      :report_detail,
      :instant_fee_created_detail,
      :print_reciept,
      :show_instant_fee_transactions,
      :list_instant_fee_transactions,
      :instant_fee_transaction_filter_by_date,
      :validate_transaction_date
    ]
  end

  role :fee_submission do
    has_permission_on [:instant_fees],
      :to=>[
      :index,
      :new_instant_fees,
      :tsearch_logic,
      :category_type,
      :handle_category,
      :handle_category_for_guest,
      :select_payment_mode,
      :print_reciept,
      :create_instant_fee,
      :instant_fee_created_detail,
      :validate_transaction_date
    ]
  end

  role :revert_transaction do
    has_permission_on [:instant_fees],
      :to=>[
      :index,
      :delete_transaction_for_instant_fee,
      :show_instant_fee_transactions,
      :list_instant_fee_transactions,
      :instant_fee_transaction_filter_by_date

    ]

    includes :fee_submission
    has_permission_on [:finance],
      :to=>[
      :fees_index
    ]

  end

  role :finance_reports do
    has_permission_on [:instant_fees],
      :to => [:report,:instant_fee_report_csv,:report_detail,:show_date_filter,:instant_fee_report_detail_csv]
  end
end