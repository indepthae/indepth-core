authorization do
  role :admin do
    includes :manage_single_statement    
  end

  role :employee do
    includes :manage_single_statement
    #do if_attribute :can_see_single_statement? => is {true}
    #end
    
  end

  
  # role :employee do
  #   has_permission_on :student,:to=>[
  #     :pdf_template_for_guardian
  #   ]
    
  # end

  # role :student do
  #   has_permission_on :student,:to=>[
  #     :pdf_template_for_guardian
  #   ]
    
  # end
  role :parent do
    includes :manage_single_statement
  end
  
  role :manage_fee do
    has_permission_on :finance_settings,:to=>[
      :single_statement_header_settings,
    ]
  end
  
  role :manage_single_statement do
    has_permission_on :student,:to=>[
      :pdf_template_for_guardian,
      :single_statement
    ]
  end
  
  role :general_admin do
    includes :admin
  end
  
end
