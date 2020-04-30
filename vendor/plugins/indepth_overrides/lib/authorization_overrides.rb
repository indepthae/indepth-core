Authorization::Engine.class_eval do
	HAS_NOT_PERMISSION = {
      :report=>[
	      :fee_collection_details,
	      :fee_collection_details_csv,
	      :course_fee_defaulters,
	      :course_fee_defaulters_csv,
	      :batch_fee_defaulters,
	      :batch_fee_defaulters_csv,
	      :students_fee_defaulters,
	      :students_fee_defaulters_csv,
	      :batch_fee_collections,
	      :batch_fee_collections_csv,
	      :student_wise_fee_defaulters,
	      :student_wise_fee_defaulters_csv,
	      :student_wise_fee_collections,
	      :student_wise_fee_collections_csv,
	      :student_fees_headwise_report,
	      :student_fees_headwise_report_pdf,
	      :student_fees_headwise_report_csv,
	      :fees_head_wise_report,
	      :batch_fees_headwise_report,
	      :collection_report,
	      :batch_head_wise_fees_csv,
	      :collection_report_csv,
	      :fee_collection_head_wise_report,
	      :update_fees_collections,
	      :fee_collection_head_wise_report_csv,
	      :employee_payroll_details
	      ],
	    :employee => [
	      :profile_payroll_details,
	      :view_payslip,
	      :payroll_and_payslips,
	      :payslip,
	      :view_payslip,
	      :profile_payroll_details,
	      :update_monthly_payslip
	      ],
	    :payroll => [
	      :assigned_employees,
	      :assign_employees,
	      :manage_payroll,
	      :employee_list,
	      :remove_from_payroll_group,
	      :create_employee_payroll,
	      :add_employee_payroll,
	      :calculate_employee_payroll_components,
	      :show,
	      :show_warning,
	      :settings
	    ],
	    :employee_payslips =>  [
	      :payslip_for_payroll_group,
	      :generate_payslips,
	      :payslip_for_employees,
	      :payslip_generation_list,
	      :generate_all_payslips,
	      :view_outdated_employees,
	      :save_employee_payslips,
	      :generate_employee_payslip,
	      :create_employee_wise_payslip,
	      :view_employee_past_payslips,
	      :view_employee_pending_payslips,
	      :view_past_payslips,
	      :view_all_employee_payslip,
	      :view_payslip,
	      :view_payslip_pdf,
	      :revert_employee_payslip,
	      :revert_all_payslips,
	      :edit_payslip,
	      :update_payslip,
	      :rejected_payslips,
	      :view_employees_with_lop,
	      :view_regular_employees,
	      :view_outdated_employees,
	      :view_all_rejected_payslips,
	      :approve_payslips,
	      :approve_payslips_range,
	      :payslip_settings,
	      :update_payslip_settings,
	      :view_sample_payslip,
	      :calculate_lop_values
	    ],
	    :payroll_categories => [
	      :index,
	      :new,
	      :create,
	      :edit,
	      :update,
	      :destroy,
	      :show,
	      :hr_formula_form,
	      :validate_formula
	    ],
	    :payroll_groups => [
	      :index,
	      :new,
	      :create,
	      :edit,
	      :update,
	      :show,
	      :destroy,
	      :payslip_generation,
	      :working_day_settings,
	      :update_working_day_settings,
	      :lop_settings,
	      :categories_formula,
	      :save_lop_settings
	    ],
	    :student => [
	      :fees,
	      :fee_details
	    ]
	  }
	RULES = [:finance_control, 
      		   :manage_roll_number,
      		   :manage_fee, 
      		   :fee_submission, 
      		   :approve_reject_payslip, 
      		   :finance_reports, 
      		   :manage_refunds, 
      		   :payroll_management, 
      		   :miscellaneous, 
      		   :revert_transaction,
      		   :manage_hr_reports
      		]
	def matching_auth_rules (roles, privileges, context)
      user = Authorization.current_user
      rules = @auth_rules
      if user.respond_to? (:general_admin?)
	      if user.general_admin?
	      	rules = @auth_rules.reject{|rule| RULES.include? rule.role}
	      end
	      is_not_permit = HAS_NOT_PERMISSION[context] && (HAS_NOT_PERMISSION[context] & privileges).present?
	      rules = []  if user.general_admin? && is_not_permit
  	  end
      rules.select {|rule| rule.matches? roles, privileges, context}
	end
end