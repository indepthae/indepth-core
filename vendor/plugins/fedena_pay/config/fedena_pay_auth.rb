authorization do

  role :payment do
    has_permission_on [:online_payments],:to =>[
      :index
    ]
    has_permission_on [:payment_settings],:to=>[
      :settings,
      :show_gateway_fields,
      :return_to_fedena_pages,
      :index,
      :transactions,
      :show_transaction_details,
    ]
    has_permission_on [:custom_gateways],:to=>[
      :index,
      :new,
      :create,
      :show,
      :manage_accounts,
      :change_financial_year,
      :update_accounts
    ]
    has_permission_on [:custom_gateways],:to=>[:edit,:update,:destroy] do
      if_attribute :self_created => is {true}
    end
    has_permission_on [:paytm_payments],:to=>[
      :get_all_fees_list,
      :get_all_fees,
      :pay_student_pending_all_fee,
      :pay_student_pending_collection_fee,
      :status_check
    ]
  end
  
  role :student do
    has_permission_on [:student_fees],
      :to=>[
      :all_fees, :paginate_paid_fees
    ] do
      if_attribute :user_id => is {user.id}
    end
    has_permission_on [:payment_settings], :to=>[:complete_payment]
  end
  
  role :parent do
    has_permission_on [:student_fees],
      :to=>[
      :all_fees, :paginate_paid_fees
    ] do
      if_attribute :user_id => is {user.parent_record.user_id}
    end
    has_permission_on [:payment_settings], :to=>[:complete_payment]
  end

  role :masteradmin do
    includes  :payment
  end

  role :admin do
    includes  :payment
  end

  role :general_settings do
    includes  :payment
  end

end