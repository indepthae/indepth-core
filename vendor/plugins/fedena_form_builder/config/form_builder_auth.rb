authorization do

  role :form_builder do
		has_permission_on [:form_templates],
      :to => [:index, :preview, :new, :edit, :create, :update, :destroy, :add_field, :remove_field, :field_settings, :add_option]

		has_permission_on [:forms],
      :to => [:preview, :publish, :close, :edit, :manage, :manage_filter, :update, :destroy, :to_students, :to_employees, :update_member_list, :to_target_students, :to_target_employees, :update_target_list]

		has_permission_on [:form_submissions],
			:to => [:show, :form_submissions_csv, :analysis, :get_target_analysis, :filter, :consolidated_report]
  end
  
  role :form_basic do
    has_permission_on [:form_builder],
      :to => [:index]

    has_permission_on [:forms],
      :to => [:show, :index, :feedback_forms, :form_submit, :edit_response, :update_response, :new_form_submission]
    
    has_permission_on [:form_submissions],
			:to => [:new, :responses, :download]
  end

  role :admin do
    includes :form_builder
    includes :form_basic
  end

  role :employee do
    includes :form_basic
  end

  role :student do
    includes :form_basic
  end

  role :parent do
    includes :form_basic
  end
end