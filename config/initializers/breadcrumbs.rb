include DateFormater
Gretel::Crumbs.layout do

  crumb :root do
    link I18n.t('home'), {:controller=>"user",:action=>"dashboard"}
  end
  ########################################
  #ICSE Report Settings
  crumb :icse_report_settings_settings do
    link "ICSE Report Settings", {:controller=>"icse_report_settings",:action=>"settings"}
    parent :icse_settings_index
  end
  ########################################
  #Cce Report Settings
  crumb :cce_report_settings_settings do
    link "Detailed CCE Report Settings", {:controller=>"cce_report_settings",:action=>"settings"}
    parent :cce_settings_index
  end
  crumb :cce_report_settings_normal_report_settings do
    link "Basic CCE Report Settings", {:controller=>"cce_report_settings",:action=>"normal_report_settings"}
    parent :cce_settings_index
  end
  crumb :observation_remarks_co_scholastic_remark_settings do
    link "Co-Scholastic Remark Settings", {:controller=>"observation_remarks",:action=>"co_scholastic_remark_settings"}
    parent :cce_settings_co_scholastic
  end
  ########################################
  #ASL Scores
  crumb :asl_scores_show do |s|
    link "ASL Scores", {:controller=>"asl_Scores",:action=>"show",:id=>s.id}
    parent :exams_show,s
  end
  crumb :asl_scores_show_previous do |s|
    link "ASL Scores", {:controller=>"asl_Scores",:action=>"show",:id=>s.id}
    parent :exam_edit_previous_marks,s,s.subject
  end
  crumb :cce_reports_asl_report do
    link "ASL Report", {:controller=>"cce_reports",:action=>"asl_report"}
    parent :cce_reports_cbse_report
  end
  ########################################
  #Upscale Settings
  crumb :cce_report_settings_upscale_settings do
    link "Upscale Settings", {:controller=>"cce_report_settings",:action=>"upscale_settings"}
    parent :cce_settings_index
  end
  crumb :cce_report_settings_cbse_co_scholastic_settings do
    link "Observation Codes Settings", {:controller=>"cce_report_settings",:action=>"cbse_co_scholastic_settings"}
    parent :cce_settings_co_scholastic
  end
  crumb :cce_reports_upscale_report do
    link "Upscale Report", {:controller=>"cce_reports",:action=>"upscale_report"}
    parent :cce_reports_index,Authorization.current_user
  end
  crumb :exam_previous_exam_marks do |b,eg|
    link eg.name, {:controller => "exam", :action => "previous_exam_marks", :batch_id => b.id,:exam_group_id=>eg.id}
    parent :exam_groups_index,b
  end

  crumb :exam_previous_exam_marks_through_course_exam do |b,eg|
    link b.name, {:controller => "exam", :action => "previous_exam_marks", :batch_id => b.id,:exam_group_id=>eg.id}
    parent :course_exam_groups_show,eg.course_exam_group
  end

  crumb :cce_report_settings_upscale_scores do |batch|
    link "Upscale Grades", {:controller=>"cce_report_settings",:action=>"upscale_scores",:batch_id =>batch.id}
    parent :exam_groups_index, batch
  end
  crumb :cce_report_settings_previous_upscale_scores do |batch|
    link "Upscale Grades", {:controller=>"cce_report_settings",:action=>"upscale_scores",:batch_id =>batch.id}
    parent :exam_groups_index, batch
  end
  crumb :exam_edit_previous_marks do |exam|
    link exam.subject.name, {:controller=>"exam",:action=>"edit_previous_marks",:exam_id =>exam.id}
    parent :exam_previous_exam_marks,[exam.subject.batch,exam.exam_group],exam.subject.batch
  end
  ########################################
  #Student Records
  crumb :student_records_index do
    link I18n.t('student_records'), {:controller=>"student_records",:action=>"index"}
  end
  crumb :record_groups_index do
    link I18n.t('manage_record_groups'), {:controller=>"record_groups",:action=>"index"}
    parent :student_records_index
  end
  crumb :records_index do |rg|
    link rg.name, {:controller => "records", :action => "index", :record_group_id => rg.id}
    parent :record_groups_index
  end
  crumb :records_new do |r|
    link I18n.t('new_record_caps'), {:controller=>"records",:action=>"new",:record_group_id=>r.record_group_id}
    parent :records_index,r.record_group
  end
  crumb :records_edit do |r|
    link I18n.t('edit_record_caps'), {:controller=>"records",:action=>"new",:record_group_id=>r.record_group_id,:id=>r.id}
    parent :records_index,r.record_group
  end
  crumb :record_groups_manage_record_groups do
    link I18n.t('courses_and_batches'), {:controller=>"record_groups",:action=>"manage_record_groups"}
    parent :student_records_index
  end
  crumb :student_records_manage_student_records do
    link I18n.t('manage_student_records'), {:controller=>"student_records",:action=>"manage_student_records"}
    parent :student_records_index
  end
  crumb :student_records_manage_student_records_for_course do |c|
    link c.course_name, {:controller => "student_records", :action => "manage_student_records_for_course", :id => c.id}
    parent :student_records_manage_student_records
  end
  crumb :student_records_handle_record_groups do |rg|
    link rg.name, {:controller => "student_records", :action => "handle_record_groups", :id => rg.id}
    parent :student_records_manage_student_records
  end
  crumb :student_records_manage_record_groups_courses do |course,record_group|
    link course.course_name, {:controller => "student_records", :action => "manage_student_records_for_course", :id => course.id,:rg_id=>record_group.id}
    parent :student_records_handle_record_groups,record_group,Authorization.current_user
  end
  crumb :record_groups_manage_record_groups_for_course do
    link I18n.t('manage_record_groups_for_course'), {:controller=>"record_groups",:action=>"manage_record_groups_for_course"}
    parent :record_groups_manage_record_groups
  end
  crumb :student_records_list_students do |b|
    if Authorization.current_user.admin? or Authorization.current_user.privileges.include?(Privilege.find_by_name('ManageStudentRecord'))
      link b.full_name, {:controller => "student_records", :action => "list_students", :id => b.id}
      parent :student_records_manage_student_records_for_course,b.course,Authorization.current_user
    elsif Authorization.current_user.is_a_batch_tutor?
      link b.full_name, {:controller => "student_records", :action => "list_students", :id => b.id}
      parent :student_records_manage_student_records,b.course,Authorization.current_user
    end
  end

  crumb :student_records_list_students_rg do |b,rg|
    link b.full_name, {:controller => "student_records", :action => "list_students", :id => b.id,:rg_id=>rg.id}
    parent :student_records_manage_record_groups_courses,[b.course,rg],Authorization.current_user
  end
  crumb :student_records_new do |s,batch|
    if Authorization.current_user.admin? or Authorization.current_user.privileges.include?(Privilege.find_by_name('ManageStudentRecord'))
      link s.full_name, {:controller => "student_records", :action => "new", :id => s.id}
      parent :student_records_list_students,batch,Authorization.current_user
    elsif Authorization.current_user.is_a_batch_tutor?
      link s.full_name, {:controller => "student_records", :action => "new", :id => s.id}
      parent :student_records_list_students,batch,Authorization.current_user
    end
  end
  crumb :student_records_new_rg do |s,batch,rg|
    link s.full_name, {:controller => "student_records", :action => "new", :id => s.id,:rg_id=>rg.id}
    parent :student_records_list_students_rg,[batch,rg],Authorization.current_user

  end
  crumb :student_records_show do |batch|
    link I18n.t('student_records_for_batch'), {:controller => "student_records", :action => "show", :id => batch.id}
    parent :student_records_manage_student_records_for_course,batch.course,Authorization.current_user
  end
  crumb :student_records_show_rg do |batch,rg|
    link I18n.t('student_records_for_batch'), {:controller => "student_records", :action => "show", :id => batch.id,:rg_id=>rg.id}
    parent :student_records_manage_record_groups_courses,[batch.course,rg],Authorization.current_user
  end

  crumb :student_records_individual_student_records do |student|
    link I18n.t('student_records'), {:controller => "student_records", :action => "individual_student_records", :id => student.id}
    parent :student_profile,student,student.user
  end
  ########################################
  #Student Attachments
  crumb :student_documents do|student|
    link I18n.t('student_documents_text_2'), {:controller=>"student_documents",:action=>"documents"}
    parent :student_profile, student, student.user
  end

  crumb :student_document_categories_index do
    link I18n.t('student_document_categories.student_document_manager'), {:controller=>"student_document_categories",:action=>"index"}
    parent :configuration_index
  end



  ########################################

  ########################################
  #Finance Module
  ########################################

  crumb :finance_index do
    link I18n.t('finance_text'), {:controller=>"finance",:action=>"index"}
  end

  crumb :financial_years_index do
    link I18n.t('manage_financial_years'), {:controller => "financial_years", :action => "index"}
    parent :finance_settings_index
  end

  crumb :finance_fees_index do
    link I18n.t('fees_text'), {:controller=>"finance",:action=>"fees_index"}
    parent :finance_index
  end

  crumb :master_fees_index do
    link I18n.t('manage_master_fees_text'), {:controller => "master_fees", :action => "index"}
    parent :finance_fees_index
  end

  crumb :master_fees_manage_masters do
    link I18n.t('manage_masters_text'), {:controller => "master_fees", :action => "manage_masters"}
    parent :master_fees_index
  end

  crumb :finance_categories do
    link I18n.t('categories'), {:controller=>"finance",:action=>"categories"}
    parent :finance_index
  end

  crumb :finance_transactions do
    link I18n.t('transactions'), {:controller=>"finance",:action=>"transactions"}
    parent :finance_index
  end

  crumb :finance_automatic_transactions do
    link I18n.t('automatic_transactions'), {:controller=>"finance",:action=>"automatic_transactions"}
    parent :finance_index
  end

  crumb :finance_payslip_index do
    link I18n.t('employee_payslip_management'), {:controller=>"finance",:action=>"payslip_index"}
    parent :finance_index
  end

  crumb :finance_reports_index do
    link I18n.t('finance_reports.finance_reports_text'), {:controller => "finance_reports", :action => "index"}
    parent :finance_index
  end

  crumb :finance_reports_payment_mode_summary do
    link I18n.t('finance_reports.payment_mode_summary_report'),
      {:controller => "finance_reports", :action => "payment_mode_summary"}
    parent :finance_reports_index
  end

  crumb :finance_reports_particular_wise_daily do
    link I18n.t('finance_reports.particular_wise_daily_transaction_report'),
      {:controller => "finance_reports", :action => "particular_wise_daily"}
    parent :finance_reports_index
  end

  crumb :finance_reports_particular_wise_student_transaction do
    link I18n.t('finance_reports.particular_wise_student_transaction_report'),
      {:controller => "finance_reports", :action => "particular_wise_student_transaction"}
    parent :finance_reports_index
  end

  # crumb :finance_finance_reports do
  #   link I18n.t('finance_reports.finance_reports_text'), {:controller=>"finance",:action=>"finance_reports"}
  #   parent :finance_index
  # end

  crumb :finance_fee_receipts do
    link I18n.t('fee_receipts'), {:controller=>"finance",:action=>"fees_receipts"}
    parent :finance_reports_index
  end

  crumb :finance_asset_liability do
    link I18n.t('asset_liability_management'), {:controller=>"finance",:action=>"asset_liability"}
    parent :finance_index
  end

  crumb :finance_master_fees do
    link I18n.t('create_fees'), {:controller=>"finance",:action=>"master_fees"}
    parent :finance_fees_index
  end

  crumb :finance_master_category_particulars do |finance_fee_category|
    link finance_fee_category.name, {:controller=>"finance",:action=>"master_category_particulars", :id => finance_fee_category.id, :batch_id => finance_fee_category.batch_id}
    parent :finance_master_fees
  end

  crumb :finance_fees_submission_index do
    link I18n.t('fees_text_index'), {:controller=>"finance",:action=>"fees_submission_index"}
    parent :finance_fees_index
  end

  crumb :finance_extensions_pay_all_fees_index do
    link I18n.t('pay_all_fees'), {:controller => "finance_extensions", :action => "pay_all_fees_index"}
    parent :finance_fees_submission_index
  end

  crumb :finance_fees_receipt_settings do
    link I18n.t('fees_receipt_settings'), {:controller=>"finance",:action=>"fees_receipt_settings"}
    parent :finance_receipt_settings
  end

  crumb :finance_pdf_receipt_settings do
    link I18n.t('pdf_receipt_settings'), {:controller=>"finance",:action=>"pdf_receipt_settings"}
    parent :finance_receipt_settings
  end

  crumb :finance_receipt_settings do
    link I18n.t('fees_receipt_settings'), {:controller=>"finance",:action=>"receipt_settings"}
    parent :finance_fees_index
  end

  crumb :finance_fee_collection do
    link I18n.t('fees_collection_text'), {:controller=>"finance",:action=>"fee_collection"}
    parent :finance_fees_index
  end

  #  crumb :finance_extensions_fees_structure_pdf do
  #    link I18n.t('fees_structure'), {:controller=>"finance_extensions",:action=>"fee_structure_pdf"}
  #    parent :finance_fees_index
  #  end

  crumb :finance_extensions_view_fees_structure do |student|
    link student.full_name, {:controller => :finance_extensions, :action => "view_fees_structure",
      :id => student.id, :id2 => student.batch_id}
    parent :finance_extensions_fees_student_structure
  end

  crumb :finance_extensions_fees_structure_for_student do |arr|
    student, collection = arr[0], arr[1]
    link "#{collection.present? ? collection.name: 'dummy_collection_name'}",
      {:controller => :finance, :action => "fees_structure_for_student",:id => student.id, :id2 => collection.id}
    parent :finance_extensions_view_fees_structure, student
  end

  crumb :finance_extensions_fees_student_structure do
    link I18n.t('fees_structure'), {:controller=>"finance_extensions",:action=>"fees_student_structure"}
    parent :finance_fees_index
  end

  crumb :finance_fees_defaulters do
    link I18n.t('fees_defaulters_text'), {:controller=>"finance",:action=>"fees_defaulters"}
    parent :finance_fees_index
  end

  crumb :finance_fees_refund do
    link I18n.t('fees_refund'), {:controller=>"finance",:action=>"fees_refund"}
    parent :finance_fees_index
  end

  crumb :finance_fees_particulars_new do
    link I18n.t('create_particulars'), {:controller=>"finance",:action=>"fees_particulars_new"}
    parent :finance_master_fees
  end

  crumb :finance_fees_particulars_create do
    link I18n.t('create_particulars'), {:controller=>"finance",:action=>"fees_particulars_new"}
    parent :finance_master_fees
  end

  crumb :finance_fee_discount_new do
    link I18n.t('create_discount_text'), {:controller=>"finance",:action=>"fee_discount_new"}
    parent :finance_master_fees
  end

  crumb :finance_fee_discounts do
    link I18n.t('fee_discounts'), {:controller=>"finance",:action=>"fee_discounts"}
    parent :finance_fee_discount_new
  end

  crumb :finance_generate_fine do
    link I18n.t('generate_fine'), {:controller=>"finance",:action=>"generate_fine"}
    parent :finance_master_fees
  end

  crumb :finance_fee_collection_new do
    link I18n.t('create_fee_collection'), {:controller=>"finance",:action=>"fee_collection_new"}
    parent :finance_fee_collection
  end

  crumb :fee_collection_schedule_jobs do
    link "#{I18n.t('scheduled_job_for')} #{I18n.t('fee_collection')}", {:controller=>"scheduled_jobs", :job_type=>"1", :action=>"index", :job_object=>"FinanceFeeCollection"}
    parent :finance_fee_collection_new
  end

  crumb :finance_fee_collection_view do
    link I18n.t('view'), {:controller=>"finance",:action=>"fee_collection_view"}
    parent :finance_fee_collection
  end

  crumb :finance_extensions_discount_particular_allocation do
    link "#{I18n.t('manage')} #{I18n.t('fee_collections')}", {:controller=>"finance_extensions",:action=>"discount_particular_allocation"}
    parent :finance_fee_collection
  end

  crumb :finance_collection_details_view do |fee_collection|
    link fee_collection.name, {:controller=>"finance",:action=>"collection_details_view", :id => fee_collection, :batch_id => fee_collection.batch_id}
    parent :finance_fee_collection_view
  end

  crumb :finance_fees_submission_batch do
    link I18n.t('fees_submission_by_batch'), {:controller=>"finance",:action=>"fees_submission_batch"}
    parent :finance_fees_submission_index
  end

  crumb :finance_fees_student_search do
    link I18n.t('fees_submit_for_student'), {:controller=>"finance",:action=>"fees_student_search",:target_action=>"student_wise_fee_payment"}
    parent :finance_fees_submission_index
  end

  crumb :finance_fees_student_search2 do
    link "#{I18n.t('pay_fees')} : #{I18n.t('particular')}-#{I18n.t('wise').capitalize}", {:controller=>"finance",:action=>"fees_student_search",:target_controller=>"finance_extensions",:target_action=>"pay_fees_in_particular_wise"}
    parent :finance_fees_submission_index
  end

  crumb :finance_pay_fees_in_particular_wise do|student|
    link student.full_name, {:controller=>"finance_extensions",:action=>"pay_fees_in_particular_wise",:id=>student.id,:target_action=>"pay_fees_in_particular_wise"}
    parent :finance_fees_student_search2
  end


  crumb :finance_view_refunds do
    link I18n.t('view_refunds'), {:controller=>"finance",:action=>"view_refunds"}
    parent :finance_fees_refund
  end

  crumb :finance_create_refund do
    link I18n.t('create_refund_rule'), {:controller=>"finance",:action=>"create_refund"}
    parent :finance_fees_refund
  end

  crumb :finance_view_refund_rules do
    link "#{I18n.t('view')} #{I18n.t('refund_rules')}", {:controller=>"finance",:action=>"view_refund_rules"}
    parent :finance_create_refund
  end

  crumb :finance_apply_refund do
    link I18n.t('apply_refund'), {:controller=>"finance",:action=>"apply_refund"}
    parent :finance_fees_refund
  end

  crumb :finance_income_create do
    link I18n.t('add_income'), {:controller=>"finance",:action=>"income_create"}
    parent :finance_transactions
  end

  crumb :finance_expense_create do
    link I18n.t('add_expense'), {:controller=>"finance",:action=>"expense_create"}
    parent :finance_transactions
  end

  crumb :finance_update_deleted_transactions do
    link I18n.t('deleted_transactions'), {:controller=>"finance",:action=>"update_deleted_transactions"}
    parent :finance_transactions
  end

  crumb :finance_expense_list do
    link I18n.t('expense'), {:controller=>"finance",:action=>"expense_list"}
    parent :finance_transactions
  end

  crumb :finance_expense_list_update do
    link I18n.t('expenses_list'), {:controller=>"finance",:action=>"expense_list_update"}
    parent :finance_expense_list
  end

  crumb :finance_expense_edit do|expense|
    link shorten_string(expense.title_was,20), {:controller=>"finance",:action=>"expense_edit",:id=>expense.id}
    parent :finance_expense_list
  end

  crumb :finance_income_list do
    link I18n.t('incomes'), {:controller=>"finance",:action=>"income_list"}
    parent :finance_transactions
  end

  crumb :finance_income_list_update do
    link I18n.t('income_list'), {:controller=>"finance",:action=>"income_list_update"}
    parent :finance_income_list
  end

  crumb :finance_income_edit do|expense|
    link shorten_string(expense.title_was,20), {:controller=>"finance",:action=>"income_edit",:id=>expense.id}
    parent :finance_income_list
  end

  crumb :finance_transactions_advanced_search do
    link I18n.t('advanced'), {:controller=>"finance",:action=>"transactions_advanced_search"}
    parent :finance_update_deleted_transactions
  end

  crumb :finance_donations do
    link I18n.t('donations'), {:controller=>"finance",:action=>"donations"}
    parent :finance_index
  end

  crumb :finance_donation do
    link I18n.t('donation'), {:controller=>"finance",:action=>"donation"}
    parent :finance_donations
  end

  crumb :finance_donation_edit do |donation|
    link I18n.t('edit')+" - "+donation.donor_was, {:controller=>"finance",:action=>"donation_edit",:id=>donation.id}
    parent :finance_donations
  end

  crumb :finance_donation_receipt do|donation|
    link donation.donor, {:controller=>"finance",:action=>"donation_receipt",:id=>donation.id}
    parent :finance_donations
  end

  crumb :finance_view_monthly_payslip do
    link I18n.t('employee_payslip_report'), {:controller=>"finance",:action=>"view_monthly_payslip"}
    parent :finance_payslip_index
  end

  crumb :finance_hr_report do
    link I18n.t('advanced_payslip_reports'), {:controller=>"hr_reports",:action=>"index"}
    parent :finance_payslip_index
  end

  crumb :finance_hr_reports_report do
    link I18n.t('generate_reports'), {:controller=>"hr_reports",:action=>"report"}
    parent :finance_hr_report
  end

  crumb :finance_hr_reports_template do
    link I18n.t('reports_text'), {:controller=>"hr_reports",:action=>"template"}
    parent :finance_hr_report
  end

  crumb :finance_approve_monthly_payslip do
    link I18n.t('one_click_aprove_payslip'), {:controller=>"finance",:action=>"approve_monthly_payslip"}
    parent :finance_payslip_index
  end

  crumb :finance_view_employee_payslip do|employee|
    link I18n.t('employee_payslip').titleize, {:controller=>"finance",:action=>"view_employee_payslip",:id=>employee.id}
    parent :finance_view_monthly_payslip
  end

  crumb :finance_monthly_report do
    link I18n.t('transaction_report'), {:controller=>"finance",:action=>"monthly_report"}
    parent :finance_reports_index
  end

  crumb :finance_update_monthly_report do |date_range|
    additional_params = date_range.length > 2 ? {:fee_account_id => date_range[2]} : {}
    link I18n.t('finance_transactions_view'), {:controller => "finance", :action=>"update_monthly_report",
      :start_date => date_range[0].to_date, :end_date => date_range[1].to_date}.merge(additional_params)
    parent :finance_monthly_report
  end

  crumb :finance_salary_department do |date_range|
    additional_params = date_range.length > 2 ? {:fee_account_id => date_range[2]} : {}
    link I18n.t('employee_salary'), {:controller => "finance", :action => "salary_department",
      :start_date => date_range[0].to_date, :end_date => date_range[1].to_date}.merge(additional_params)
    parent :finance_update_monthly_report, date_range
  end

  crumb :finance_donations_report do |date_range|
    additional_params = date_range.length > 2 ? {:fee_account_id => date_range[2]} : {}
    link I18n.t('donations'), {:controller => "finance", :action => "donations_report",
      :start_date => date_range[0].to_date, :end_date => date_range[1].to_date}.merge(additional_params)
    parent :finance_update_monthly_report, date_range
  end

  crumb :finance_fees_report do |date_range|
    additional_params = date_range.length > 2 ? {:fee_account_id => date_range[2]} : {}
    link I18n.t('student_fees'), {:controller => "finance", :action =>"fees_report", :start_date => date_range.first.to_date,
      :end_date => date_range[1].to_date}.merge(additional_params)
    parent :finance_update_monthly_report, date_range
  end

  crumb :finance_course_wise_collection_report do |fee_collection_details|
    additional_params = fee_collection_details[1].length > 2 ? {:fee_account_id => fee_collection_details[1][2]} : {}
    link fee_collection_details.first.name, {:controller => "finance", :action => "course_wise_collection_report",
      :id => fee_collection_details.first.id, :start_date => fee_collection_details.last[0].to_date,
      :end_date => fee_collection_details.last[1].to_date}.merge(additional_params)
    parent :finance_fees_report, fee_collection_details[1]
  end
  crumb :finance_income_details do|detail_object|
    additional_params = detail_object.length > 2 ? {:fee_account_id => detail_object[2]} : {}
    link detail_object.first.name, {:controller => "finance", :action => "income_details", :id => detail_object[0].id,
      :start_date => detail_object[1][0].to_date, :end_date => detail_object[1][1].to_date}.merge(additional_params)
    parent :finance_update_monthly_report, detail_object[1]
  end

  crumb :finance_salary_employee do |salary_object|
    additional_params = salary_object.last.length > 2 ? {:fee_account_id => salary_object.last[2]} : {}
    link I18n.t('department') + " : " + salary_object.first.name, {:controller => "finance",
      :action => "salary_employee", :id => salary_object.first.id, :start_date => salary_object.last[0].to_date,
      :end_date => salary_object.last[1].to_date}.merge(additional_params)
    parent :finance_salary_department, salary_object.last
  end

  crumb :employee_payslips_finance_report do |list|
    link I18n.t('employee_payslip').titleize, {:controller=>"finance",:action=>"view_employee_payslip",:id=>list.last.id, :from => 'finance_report'}
    parent :finance_salary_employee, list.first
  end

  crumb :finance_batch_fees_report do |batch_object|
    additional_params = batch_object[2].length > 2 ? {:fee_account_id => batch_object[2][2]} : {}
    link batch_object[1].full_name, {:controller => "finance", :action => "batch_fees_report",
      :id => batch_object[0].id}.merge(additional_params)
    parent :finance_course_wise_collection_report, [batch_object[0], batch_object[2]]
  end

  crumb :finance_compare_report do
    link I18n.t('compare_transactions'), {:controller=>"finance",:action=>"compare_report"}
    parent :finance_reports_index
  end

  crumb :finance_report_compare do
    link I18n.t('transaction_comparision'), {:controller=>"finance",:action=>"report_compare"}
    parent :finance_compare_report
  end

  crumb :finance_asset do
    link I18n.t('asset'), {:controller=>"finance",:action=>"asset"}
    parent :finance_asset_liability
  end

  crumb :finance_view_asset do
    link I18n.t('view'), {:controller=>"finance",:action=>"view_asset"}
    parent :finance_asset
  end

  crumb :finance_each_asset_view do|asset|
    link shorten_string(asset.title,20), {:controller=>"finance",:action=>"each_asset_view",:id=>asset.id}
    parent :finance_view_asset
  end

  crumb :finance_liability do
    link I18n.t('liability'), {:controller=>"finance",:action=>"liability"}
    parent :finance_asset_liability
  end

  crumb :finance_view_liability do
    link I18n.t('view'), {:controller=>"finance",:action=>"view_liability"}
    parent :finance_liability
  end

  crumb :finance_each_liability_view do|liability|
    link shorten_string(liability.title,20), {:controller=>"finance",:action=>"each_liability_view",:id=>liability.id}
    parent :finance_view_liability
  end

  crumb :finance_student_wise_fee_payment do|student|
    link student.full_name, {:controller=>"finance",:action=>"student_wise_fee_payment",:id=>student.id}
    parent :finance_fees_student_search
  end

  crumb :finance_fees_student_dates do|student|
    link "#{I18n.t('fee_collection')} #{I18n.t('wise')} #{I18n.t('payment')}", {:controller=>"finance",:action=>"fees_student_dates",:id=>student.id}
    parent :finance_student_wise_fee_payment,student
  end

  crumb :finance_extensions_pay_all_fees do|student|
    link "#{I18n.t('pay_all_fees')}", {:controller=>"finance_extensions",:action=>"pay_all_fees",:id=>student.id}
    parent :finance_student_wise_fee_payment,student
  end

  crumb :finance_fees_student_dates_pay_all_fees do |student|
    link student.full_name, {:controller => "finance_extensions", :action => "pay_all_fees", :id => student.id}
    parent :finance_extensions_pay_all_fees_index
  end

  crumb :finance_fees_structure_dates do|student|
    link student.full_name, {:controller=>"finance",:action=>"fees_structure_dates",:id=>student.id}
    parent :finance_fees_student_structure_search
  end

  crumb :finance_pay_fees_defaulters do|student|
    link student.full_name, {:controller=>"finance",:action=>"pay_fees_defaulters",:id=>student.id}
    parent :finance_fees_defaulters
  end

  crumb :finance_fees_refund_dates do|student|
    link student.full_name, {:controller=>"finance",:action=>"fees_refund_dates",:id=>student.id}
    parent :finance_apply_refund
  end

  crumb :finance_refund_student_view do|student|
    link I18n.t('view_refunds'), {:controller=>"finance",:action=>"refund_student_view",:id=>student.id}
    parent :student_fees,student
  end
  crumb :finance_add_additional_details_for_donation do
    link I18n.t('add_additional_details_for_donation'), {:controller => "finance", :action => "add_additional_details_for_donation"}
    parent :finance_donations
  end
  crumb :finance_edit_additional_details_for_donation do
    link I18n.t('edit_additional_details_donation'), {:controller => "finance", :action => "edit_additional_details_for_donation"}
    parent :finance_donations
  end

  crumb :payroll_groups_index_finance do
    link I18n.t('payroll_groups').titleize, {:controller=>"payroll_groups",:action=>"index", :finance => 1}
    parent :finance_payslip_index
  end

  crumb :payroll_groups_show_finance do |group|
    link I18n.t('view_payroll_group').titleize, {:controller=>"payroll_groups",:action=>"show",:id=>group.id, :finance => 1}
    parent :payroll_groups_index_finance
  end

  crumb :payroll_groups_assigned_employees_finance do |group|
    link I18n.t('employees'), {:controller=>"payroll",:action=>"assigned_employees", :id => group.id, :finance => 1}
    parent :payroll_groups_show_finance, group, Authorization.current_user
  end

  crumb :assigned_employee_view_payroll_finance do |list|
    group = PayrollGroup.find(list.last.id)
    link I18n.t('view_payroll').titleize, {:controller => 'payroll', :action => 'show', :id => list.first.id, :from => 'assigned_employees', :finance => 1}
    parent :payroll_groups_assigned_employees_finance, group, Authorization.current_user
  end

  crumb :employee_payslips_payslip_for_employees_finance do
    link I18n.t('payslip_for_employees'), {:controller=>"employee_payslips",:action=>"payslip_for_employees", :finance => 1}
    parent :finance_payslip_index
  end

  crumb :employee_payslips_payslip_for_employees_finance_archived do
    link I18n.t('archived_employee_payslips'), {:controller=>"employee_payslips",:action=>"payslip_for_employees", :finance => 1, :archived => 1}
    parent :finance_payslip_index
  end

  crumb :employee_payslips_view_employee_past_payslips_finance do |employee|
    link "#{I18n.t('generated_payslips')} - #{shorten_string(employee.first_name, 10)}", {:controller=>"employee_payslips",:action=>"view_employee_past_payslips", :employee_id => employee.id, :finance => 1}
    parent :employee_payslips_payslip_for_employees_finance
  end

  crumb :employee_payslips_view_employee_past_payslips_finance_archived do |employee|
    link "#{I18n.t('generated_payslips')} - #{shorten_string(employee.first_name, 10)}", {:controller=>"employee_payslips",:action=>"view_employee_past_payslips", :employee_id => employee.id, :finance => 1, :archived => 1}
    parent :employee_payslips_payslip_for_employees_finance_archived
  end

  crumb :past_payslips_view_payroll_finance do |list|
    link I18n.t('view_payroll').titleize, {:controller => 'payroll', :action => 'show', :id => list.first.id, :from => 'past_payslips_finance', :finance => 1}
    parent :employee_payslips_view_employee_past_payslips_finance, list.last, Authorization.current_user
  end

  crumb :past_payslips_archived_view_payroll_finance do |list|
    link I18n.t('view_payroll').titleize, {:controller => 'payroll', :action => 'show', :id => list.first.id, :from => 'past_payslips_finance_archived', :finance => 1}
    parent :employee_payslips_view_employee_past_payslips_finance_archived, list.last, Authorization.current_user
  end

  crumb :employee_payslips_view_payslip_finance do |employee_payslip|
    link I18n.t('employee_payslip').titleize, {:controller=>"employee_payslips",:action=>"view_payslip", :id => employee_payslip.last.id, :finance => 1}
    parent :employee_payslips_view_employee_past_payslips_finance, employee_payslip.first, Authorization.current_user
  end

  crumb :employee_payslips_view_payslip_finance_archived do |employee_payslip|
    link I18n.t('employee_payslip').titleize, {:controller=>"employee_payslips",:action=>"view_payslip", :id => employee_payslip.last.id, :finance => 1, :from => 'employee_payslips_finance_archived'}
    parent :employee_payslips_view_employee_past_payslips_finance_archived, employee_payslip.first, Authorization.current_user
  end

  crumb :employee_payslips_view_all_rejected_payslips_finance do
    link I18n.t('rejected_payslips').titleize, {:controller=>"employee_payslips",:action=>"view_all_rejected_payslips", :finance => 1, :from => 'payslip_employees' }
    parent :employee_payslips_payslip_for_employees_finance
  end

  crumb :employee_payslips_rejected_payslips_view_payslip_finance do |employee_payslip|
    link I18n.t('employee_payslip').titleize, {:controller=>"employee_payslips",:action=>"view_payslip", :id => employee_payslip.id, :finance => 1, :from => 'payslip_employees'}
    parent :employee_payslips_view_all_rejected_payslips_finance
  end

  crumb :employee_payslips_payslip_for_payroll_group_finance do
    link I18n.t('payslip_for_payroll_group'), {:controller=>"employee_payslips",:action=>"payslip_for_payroll_group", :finance => 1}
    parent :finance_payslip_index
  end

  crumb :employee_payslips_view_past_payslips_finance do |payroll_group|
    link I18n.t('generated_payslips'), {:controller=>"employee_payslips",:action=>"view_past_payslips", :id => payroll_group.id, :finance => 1}
    parent :employee_payslips_payslip_for_payroll_group_finance
  end

  crumb :employee_payslips_payslip_generation_list_past_finance do |list|
    link I18n.t('view_payslips').titleize, {:controller=>"employee_payslips",:action=>"payslip_generation_list", :id => list.first.id, :start_date => list.last.first ,:end_date => list.last.last, :from => 'past_payslips_finance', :finance => 1 }
    parent :employee_payslips_view_past_payslips_finance, list.first, Authorization.current_user
  end

  crumb :finance_view_employee_payslip_past_payslips do|list|
    link I18n.t('employee_payslip').titleize, {:controller=>"finance",:action=>"view_employee_payslip",:id=>list.first.id, :from => 'past_payslips_finance', :finance => 1}
    parent :employee_payslips_payslip_generation_list_past_finance, list.last, Authorization.current_user
  end

  crumb :employee_payslips_view_all_employee_payslip_past_finance do |list|
    link I18n.t('view_all_payslips').titleize, {:controller=>"employee_payslips",:action=>"view_all_employee_payslip", :id => list.first.id, :start_date => list.last.first ,:end_date => list.last.last, :from => 'past_payslips', :finance => 1}
    parent :employee_payslips_payslip_generation_list_past_finance, list, Authorization.current_user
  end

  crumb :finance_view_all_payslips_employee_payslips do|list|
    link I18n.t('employee_payslip').titleize, {:controller=>"finance",:action=>"view_employee_payslip",:id=>list.first.id, :from => 'all_payslips_finance'}
    parent :employee_payslips_view_all_employee_payslip_past_finance, list.last, Authorization.current_user
  end

  crumb :employee_payslips_approve_payslips do
    link I18n.t('approve_payslips'), {:controller=>"employee_payslips",:action=>"approve_payslips"}
    parent :finance_payslip_index
  end

  crumb :employee_payslips_approve_payslips_range do |list|
    link "#{I18n.t('approve_payslips').titleize} - #{I18n.t('pay_period').titleize}", {:controller=>"employee_payslips",:action=>"approve_payslips_range", :start_date => list.first, :end_date => list.last}
    parent :employee_payslips_approve_payslips
  end

  crumb :employee_payslips_payslip_generation_list_approve_payslips do |list|
    link I18n.t('view_payslips').titleize, {:controller=>"employee_payslips",:action=>"payslip_generation_list", :id => list.first.id, :start_date => list.last.first ,:end_date => list.last.last, :from => 'approve_payslips', :finance => 1 }
    parent :employee_payslips_approve_payslips_range, list.last
  end

  crumb :finance_view_employee_payslip_approve_payslips do|list|
    link I18n.t('employee_payslip').titleize, {:controller=>"finance",:action=>"view_employee_payslip",:id=>list.first.id, :from => 'approve_payslips', :finance => 1}
    parent :employee_payslips_payslip_generation_list_approve_payslips, list.last, Authorization.current_user
  end

  crumb :employee_payslips_view_all_employee_payslip_approve_payslips do |list|
    link I18n.t('view_all_payslips').titleize, {:controller=>"employee_payslips",:action=>"view_all_employee_payslip", :id => list.first.id, :start_date => list.last.first ,:end_date => list.last.last, :from => 'approve_payslips', :finance => 1}
    parent :employee_payslips_payslip_generation_list_approve_payslips, list, Authorization.current_user
  end

  crumb :finance_view_all_approve_payslips_payslips do |list|
    link I18n.t('employee_payslip').titleize, {:controller=>"finance",:action=>"view_employee_payslip",:id=>list.first.id, :from => 'approve_payslips_all'}
    parent :employee_payslips_view_all_employee_payslip_approve_payslips, list.last, Authorization.current_user
  end

  crumb :group_payslips_view_all_rejected_payslips_finance do
    link I18n.t('rejected_payslips').titleize, {:controller=>"employee_payslips",:action=>"view_all_rejected_payslips", :finance => 1, :from => 'payslip_group'}
    parent :employee_payslips_payslip_for_payroll_group_finance
  end

  crumb :group_payslips_rejected_payslips_view_payslip_finance do |employee_payslip|
    link I18n.t('employee_payslip').titleize, {:controller=>"employee_payslips",:action=>"view_payslip", :id => employee_payslip.id, :finance => 1, :from => 'payslip_group'}
    parent :group_payslips_view_all_rejected_payslips_finance
  end

  ###################################################
  # => advance payment fees for students            #
  ###################################################
  crumb :advance_payment_fees_advance_fees_index do
    link I18n.t('advance_fees_payment'), {:controller=>"advance_payment_fees",:action=>"advance_fees_index"}
    parent :finance_fees_index
  end

  crumb :advance_payment_fees_advance_fees_particular_new do
    link I18n.t('advance_fee_particular'), {:controller=>"advance_payment_fees",:action=>"advance_fees_particular_new"}
    parent :advance_payment_fees_advance_fees_index
  end

  crumb :advance_payment_fees_advance_fees_particular_create do
    link I18n.t('advance_payment_for_student'), {:controller=>"advance_payment_fees",:action=>"advance_fees_particular_create"}
    parent :finance_index
  end

  crumb :advance_payment_fees_advance_fees_collection_index do
    link I18n.t('fees_collection_desc'), {:controller=>"advance_payment_fees",:action=>"advance_fees_collection_index"}
    parent :advance_payment_fees_advance_fees_index
  end

  crumb :advance_payment_fees_report_index do
    link I18n.t('students_wallet_report'), {:controller=>"advance_payment_fees",:action=>"report_index"}
    parent :finance_reports_index
  end

  crumb :advance_payment_fees_wallet_credit_transaction_report do
    link I18n.t('wallet_income_report'), {:controller=>"advance_payment_fees",:action=>"wallet_credit_transaction_report"}
    parent :finance_monthly_report
  end

  crumb :advance_payment_fees_wallet_debit_transaction_report do
    link I18n.t('wallet_expense_report'), {:controller=>"advance_payment_fees",:action=>"wallet_debit_transaction_report"}
    parent :finance_monthly_report
  end

  crumb :advance_payment_fees_advance_fee_categories_list do
    link I18n.t('advance_fee_categories_text'), {:controller=>"advance_payment_fees",:action=>"advance_fee_categories_list"}
    parent :advance_payment_fees_advance_fees_index
  end
  
  crumb :advance_fee_students do |student|
    link I18n.t('advance_fees_text'), {:controller=>"advance_payment_fees",:action=>"advance_fee_categories_list"}
    parent :student_fees, student, student.user
  end

  crumb :advance_payment_fees_for_students do |student|
    link I18n.t('advance_fees_payment'), {:controller=>"advance_payment_fees",:action=>"advance_payment_by_student"}
    parent :advance_fee_students, student, student.user
  end


  ##################################################
  #HR Module
  ##################################################

  crumb :employee_hr do
    link I18n.t('hr'), {:controller=>"employee",:action=>"hr"}
  end

  crumb :employee_settings do
    link I18n.t('settings'), {:controller=>"employee",:action=>"settings"}
    parent :employee_hr
  end

  crumb :employee_employee_management do
    link I18n.t('employee_management_text'), {:controller=>"employee",:action=>"employee_management"}
    parent :employee_hr
  end

  crumb :employee_employee_attendance do
    link I18n.t('employee_leave_management').titleize, {:controller=>"employee",:action=>"employee_attendance"}
    parent :employee_hr
  end

  crumb :employee_attendance_employee_leaves do |employee|
    link I18n.t('employee_leaves').titleize, {:controller=>"employee_attendance",:action=>"employee_leaves", :id => employee.id}
    parent :employee_profile,employee,employee.user
  end

  crumb :employee_attendance_my_leaves do |employee|
    link I18n.t('my_leaves').titleize, {:controller=>"employee_attendance",:action=>"my_leaves", :id => employee.id, :from => "profile"}
    parent :employee_profile,employee,employee.user
  end

  crumb :employee_attendance_my_leave_applications do |employee|
    link I18n.t('my_leave_applications').titleize, {:controller=>"employee_attendance",:action=>"my_leave_applications", :id => employee.id, :from => "employee"}
    parent :employee_attendance_my_leaves,employee,employee.user
  end

  crumb :employee_attendance_reportees_leave_applications do |employee|
    link I18n.t('reportees_leave_applications').titleize, {:controller=>"employee_attendance",:action=>"reportees_leave_applications", :id => employee.id, :from => "manager"}
    parent :employee_attendance_reportees_leaves,employee,employee.user
  end

  crumb :employee_attendance_pending_leave_applications do |employee|
    link I18n.t('pending_leave_applications').titleize, {:controller=>"employee_attendance",:action=>"pending_leave_applications", :id => employee.id, :from => "manager", :status => "pending"}
    parent :employee_attendance_reportees_leaves,employee,employee.user
  end

  crumb :employee_edit_leave_balance do |employee|
    link I18n.t('employee_leave_balance').titleize, {:controller=>"employee",:action=>"edit_leave_balance", :id => employee.id}
    parent :employee_attendance_my_leaves ,employee,employee.user
  end

  crumb :employee_attendance_reportees_leaves do |employee|
    link I18n.t('reportees_leaves').titleize, {:controller=>"employee_attendance",:action=>"reportees_leaves", :id => employee.id, :from => "reportees_leaves"}
    parent :employee_attendance_employee_leaves,employee, employee.user
  end

  crumb :employee_search do
    link I18n.t('employees'), {:controller=>"employee",:action=>"search"}
    parent :employee_hr
  end

  crumb :employee_department_payslip do
    link I18n.t('employee_payslip'), {:controller=>"employee",:action=>"department_payslip"}
    parent :employee_hr
  end

  crumb :employee_add_category do
    link I18n.t('employee_category').titleize, {:controller=>"employee",:action=>"add_category"}
    parent :employee_settings
  end

  crumb :employee_add_position do
    link I18n.t('employee_position').titleize, {:controller=>"employee",:action=>"add_position"}
    parent :employee_settings
  end

  crumb :employee_add_department do
    link I18n.t('employee_department').titleize, {:controller=>"employee",:action=>"add_department"}
    parent :employee_settings
  end

  crumb :employee_add_grade do
    link I18n.t('employee_grade').titleize, {:controller=>"employee",:action=>"add_grade"}
    parent :employee_settings
  end

  crumb :employee_add_bank_details do
    link I18n.t('bank_detail').titleize, {:controller=>"employee",:action=>"add_bank_details"}
    parent :employee_settings
  end

  crumb :employee_add_additional_details do
    link I18n.t('additional_detail'), {:controller=>"employee",:action=>"add_additional_details"}
    parent :employee_settings
  end

  crumb :employee_subject_assignment do
    link I18n.t('employee_subject_association'), {:controller=>"employee",:action=>"subject_assignment"}
    parent :employee_employee_management
  end

  crumb :employee_attendance_add_leave_types do
    link I18n.t('add_leave_type').titleize, {:controller=>"employee_attendance",:action=>"add_leave_types"}
    parent :employee_attendance_list_leave_types
  end

  crumb :employee_attendance_list_leave_types do
    link I18n.t('leave_types').titleize, {:controller=>"employee_attendance",:action=>"list_leave_types"}
    parent :employee_settings
  end
  crumb :employee_attendances_index do
    link I18n.t('attendance_register'), {:controller=>"employee_attendances",:action=>"index"}
    parent :employee_employee_attendance
  end

  crumb :employee_attendance_report do
    link I18n.t('attendance_report'), {:controller=>"employee_attendance",:action=>"report"}
    parent :employee_employee_attendance
  end

  crumb :employee_attendance_filter_attendance_report do
    link I18n.t('filterd_reports_text'), {:controller=>"employee_attendance",:action=>"filter_attendance_report"}
    parent :employee_attendance_report
  end


  crumb :employee_attendance_leaves do |employee|
    link I18n.t('leave_management'), {:controller=>"employee_attendance",:action=>"leaves",:id=>employee.id}
    parent :employee_profile,employee,employee.user
  end

  crumb :employee_attendance_new_leave_applications do |employee|
    link I18n.t('leave_management'), {:controller=>"employee_attendance",:action=>"new_leave_applications",:id=>employee.id}
    parent :employee_attendance_leaves,employee
  end

  crumb :employee_attendance_view_attendance do |list|
    link I18n.t('view_attendance').titleize, {:controller=>"employee_attendance",:action=>"view_attendance", :id => list.first.id, :from => list.last}
    parent_action = list.last
    case parent_action
    when "report"
      parent "employee_attendance_additional_leave_detailed".to_sym ,list, list[1].user
    when "profile"
      parent "employee_attendance_my_leaves".to_sym , list[1], list[1].user
    when "additional_leave_detailed"
      parent "employee_attendance_#{parent_action}".to_sym ,list, list[1].user
    when "reportees_leaves"
      parent "employee_attendance_additional_leave_detailed".to_sym ,list, list[1].user
    else
      parent "employee_attendance_my_leaves".to_sym , list[1], list[1].user
    end
  end

  crumb :employee_attendance_leave_application do |list|
    link I18n.t('approve_deny'), {:controller=>"employee_attendance",:action=>"leave_application",:id=>list.first}
    emp = list[1]
    parent_action = list.last
    case parent_action
    when "my_leave_applications"
      parent "employee_attendance_additional_leave_detailed".to_sym ,list, list[1].user
    when "report"
      parent "employee_attendance_additional_leave_detailed".to_sym ,list, list[1].user
    when "additional_leave_detailed"
      parent "employee_attendance_#{parent_action}".to_sym , list, list[1].user
    when "reportees_leaves"
      parent "employee_attendance_additional_leave_detailed".to_sym , list, list[1].user
    when "profile"
      parent "employee_attendance_my_leaves".to_sym, list[1], list[1].user
    else
      parent "employee_attendance_#{parent_action}".to_sym , Authorization.current_user.employee_record,Authorization.current_user
    end

  end

  crumb :employee_attendance_manual_reset do
    link I18n.t('reset_leave'), {:controller=>"employee_attendance",:action=>"manual_reset"}
    parent :employee_employee_attendance
  end

  crumb :employee_select_department_employee do
    link I18n.t('select_employee'), {:controller=>"employee",:action=>"select_department_employee"}
    parent :employee_payslip
  end

  crumb :employee_rejected_payslip do
    link I18n.t('rejected_employee'), {:controller=>"employee",:action=>"rejected_payslip"}
    parent :employee_payslip
  end

  crumb :employee_advanced_search do
    link I18n.t('advanced'), {:controller=>"employee",:action=>"advanced_search"}
    parent :employee_search
  end

  crumb :employee_edit_category do|category|
    link I18n.t('edit_employee_category'), {:controller=>"employee",:action=>"edit_category",:id=>category.id}
    parent :employee_add_category
  end

  crumb :employee_edit_position do|position|
    link I18n.t('edit_employee_position'), {:controller=>"employee",:action=>"edit_position",:id=>position.id}
    parent :employee_add_position
  end

  crumb :employee_edit_department do|department|
    link I18n.t('edit_employee_department'), {:controller=>"employee",:action=>"edit_department",:id=>department.id}
    parent :employee_add_department
  end

  crumb :employee_edit_grade do|grade|
    link I18n.t('edit_employee_grade').titleize, {:controller=>"employee",:action=>"edit_grade",:id=>grade.id}
    parent :employee_add_grade
  end

  crumb :employee_edit_bank_details do|bank_detail|
    link I18n.t('edit_bank_details').titleize, {:controller=>"employee",:action=>"edit_bank_details",:id=>bank_detail.id}
    parent :employee_add_bank_details
  end

  crumb :employee_attendance_edit_leave_types do |leave_type|
    link I18n.t('edit')+" - "+leave_type.name_was, {:controller=>"employee_attendance",:action=>"edit_leave_types",:id=>leave_type.id}
    parent :employee_attendance_list_leave_types
  end

  crumb :employee_attendance_emp_attendance do|emp|
    link emp.first_name_was, {:controller=>"employee_attendance",:action=>"emp_attendance",:id=>emp.id}
    parent :employee_attendance_report
  end

  crumb :archived_employee_profile do|emp|
    link emp.first_name_was, {:controller=>"archived_employee",:action=>"profile",:id=>emp.id}
    parent :employee_advanced_search
  end


  crumb :employee_attendance_additional_leave_detailed do |list|
    link I18n.t('employee_leave_details').titleize, {:controller=>"employee_attendance",:action=>"additional_leave_detailed",:id=>list[1].id, :from =>list.last}
    if list.last == "reportees_leaves"
      parent :employee_attendance_reportees_leaves, Authorization.current_user.employee_record, Authorization.current_user
    elsif list.last == "leave_balance_report"
      parent :employee_attendance_leave_balance_report
    else
      parent :employee_attendance_report
    end
  end

  crumb :employee_attendance_leave_history do|employee|
    link I18n.t('leave_history'), {:controller=>"employee_attendance",:action=>"leave_history",:id=>employee.id}
    parent :employee_attendance_emp_attendance,employee
  end

  crumb :employee_attendance_leave_history_without_permission do|employee|
    link I18n.t('leave_history'), {:controller=>"employee_attendance",:action=>"leave_history",:id=>employee.id}
    parent :employee_attendance_leaves,employee
  end

  crumb :employee_attendance_own_leave_application do|employee|
    link I18n.t('leave_application'), {:controller=>"employee_attendance",:action=>"own_leave_application",:id=>employee.id}
    parent :employee_attendance_my_leave_applications,employee,employee.user
  end

  crumb :employee_view_all do
    link I18n.t('view_all'), {:controller=>"employee",:action=>"view_all"}
    parent :employee_search
  end

  crumb :employee_attendance_employee_leave_details do |emp|
    link emp.first_name, {:controller=>"employee_attendance",:action=>"edit_leave_types",:id=>emp.id}
    parent :employee_attendance_reset_leaves
  end

  crumb :employee_payslips_view_all_employee_payslip do |list|
    link I18n.t('view_all_payslips').titleize, {:controller=>"employee_payslips",:action=>"view_all_employee_payslip", :id => list.first.id, :start_date => list.last.first ,:end_date => list.last.last}
    parent :employee_payslips_payslip_generation_list, list, Authorization.current_user
  end

  crumb :employee_payslips_view_all_employee_payslip_past do |list|
    link I18n.t('view_all_payslips').titleize, {:controller=>"employee_payslips",:action=>"view_all_employee_payslip", :id => list.first.id, :start_date => list.last.first ,:end_date => list.last.last, :from => 'past_payslips'}
    parent :employee_payslips_payslip_generation_list_past, list, Authorization.current_user
  end

  crumb :employee_payslips_view_all_rejected_payslips do
    link I18n.t('rejected_payslips').titleize, {:controller=>"employee_payslips",:action=>"view_all_rejected_payslips"}
    parent :employee_payroll_and_payslips
  end

  crumb :employee_payslips_generated_payslips do |list|
    link I18n.t('generated_payslips'), {:controller=>"employee_payslips",:action=>"generated_payslips", :id => list.first.id, :start_date => list.last.first ,:end_date => list.last.last}
    parent :employee_payslips_view_past_payslips, list.first
  end

  crumb :employee_payslips_payslip_generation_list do |list|
    link I18n.t('view_payslips').titleize, {:controller=>"employee_payslips",:action=>"payslip_generation_list", :id => list.first.id, :start_date => list.last.first ,:end_date => list.last.last }
    parent :employee_payslips_generate_payslips, list, Authorization.current_user
  end

  crumb :employee_payslips_payslip_generation_list_past do |list|
    link I18n.t('view_payslips').titleize, {:controller=>"employee_payslips",:action=>"payslip_generation_list", :id => list.first.id, :start_date => list.last.first ,:end_date => list.last.last, :from => 'past_payslips' }
    parent :employee_payslips_view_past_payslips, list.first, Authorization.current_user
  end

  crumb :employee_payslips_view_employees_with_lop do |list|
    link I18n.t('employees_with_lop'), {:controller=>"employee_payslips",:action=>"view_employees_with_lop", :id => list.first.id, :start_date => list.last.first,:end_date => list.last.last}
    parent :employee_payslips_generate_payslips, list
  end

  crumb :employee_payslips_view_regular_employees do |list|
    link I18n.t('regular_employees').titleize, {:controller=>"employee_payslips",:action=>"view_regular_employees", :id => list.first.id, :start_date => list.last.first,:end_date => list.last.last}
    parent :employee_payslips_generate_payslips, list
  end

  crumb :employee_payslips_view_outdated_employees do |list|
    link I18n.t('employees_with_outdated_payroll'), {:controller=>"employee_payslips",:action=>"view_outdated_employees" , :id => list.first.id, :start_date => list.last.first,:end_date => list.last.last}
    parent :employee_payslips_generate_payslips, list
  end

  crumb :employee_payslips_edit do |payslip_id|
    link I18n.t('edit_payslip').titleize, {:controller=>"employee_payslips",:action=>"edit_payslip", :id => payslip_id, :from => 'view_all_rejected_payslips'}
    parent :employee_payslips_view_all_rejected_payslips, Authorization.current_user
  end

  crumb :employee_payslips_regenerate_payslip_rejected_payslips do |list|
    link I18n.t('generate_employee_payslip'), {:controller=>"employee_payslips",:action=>"generate_employee_payslip", :start_date => list.last.first,:end_date => list.last.last, :employee_id => list.first.last.id, :from => "view_all_rejected_payslips"}
    parent :employee_payslips_edit, list.first.first, Authorization.current_user
  end

  crumb :employee_payslips_payslip_settings do
    link I18n.t('payslip_settings'), {:controller=>"employee_payslips",:action=>"payslip_settings"}
    parent :employee_payroll_and_payslips
  end

  crumb :employee_payslips_update_payslip_settings do
    link I18n.t('payslip_settings'), {:controller=>"employee_payslips",:action=>"payslip_settings"}
    parent :employee_payroll_and_payslips
  end

  crumb :employee_profile do|emp|
    link emp.first_name_was, {:controller=>"employee",:action=>"profile",:id=>emp.id}
    parent :employee_search,emp
  end

  crumb :employee_change_reporting_manager do|emp|
    link I18n.t('change_reporting_manager'), {:controller=>"employee",:action=>"change_reporting_manager",:id=>emp.id}
    parent :employee_profile,emp,emp.user
  end

  crumb :employee_edit1 do|emp|
    link I18n.t('general_details_edit'), {:controller=>"employee",:action=>"edit1",:id=>emp.id}
    parent :employee_profile,emp,emp.user
  end

  crumb :employee_edit_personal do|emp|
    link I18n.t('personal_details_edit'), {:controller=>"employee",:action=>"edit_personal",:id=>emp.id}
    parent :employee_profile,emp,emp.user
  end

  crumb :employee_edit2 do|emp|
    link I18n.t('address_edit'), {:controller=>"employee",:action=>"edit2",:id=>emp.id}
    parent :employee_profile,emp,emp.user
  end

  crumb :employee_edit_contact do|emp|
    link I18n.t('contact_edit'), {:controller=>"employee",:action=>"edit_contact",:id=>emp.id}
    parent :employee_profile,emp,emp.user
  end

  crumb :employee_edit3 do|emp|
    link I18n.t('bank_details_edit'), {:controller=>"employee",:action=>"edit3",:id=>emp.id}
    parent :employee_profile,emp,emp.user
  end

  crumb :employee_admission3_1 do|emp|
    link I18n.t('additional_detail_edit'), {:controller=>"employee",:action=>"admission3_1",:id=>emp.id}
    parent :employee_profile,emp,emp.user
  end

  crumb :employee_remove_subordinate_employee do|emp|
    link I18n.t('remove_subordinate_employee'), {:controller=>"employee",:action=>"remove_subordinate_employee",:id=>emp.id}
    parent :employee_profile,emp,emp.user
  end

  crumb :employee_remove do|emp|
    link I18n.t('remove'), {:controller=>"employee",:action=>"remove",:id=>emp.id}
    parent :employee_profile,emp,emp.user
  end

  crumb :employee_change_to_former do|emp|
    link I18n.t('archive'), {:controller=>"employee",:action=>"change_to_former",:id=>emp.id}
    parent :employee_remove,emp
  end

  crumb :payroll_manage_payroll do|emp|
    link I18n.t('add_payroll'), {:controller=>"employee",:action=>"manage_payroll",:id=>emp.id}
    parent :employee_profile,emp,emp.user
  end


  crumb :employee_admission1 do
    link I18n.t('employee_admission'), {:controller=>"employee",:action=>"admission1"}
    parent :employee_employee_management
  end

  crumb :employee_admission2 do |emp|
    link I18n.t('address'), {:controller=>"employee",:action=>"admission2",:id=>emp.id}
    parent :employee_profile,emp,emp.user
  end

  crumb :employee_admission3 do |emp|
    link I18n.t('bank_info'), {:controller=>"employee",:action=>"admission3",:id=>emp.id}
    parent :employee_profile,emp,emp.user
  end

  crumb :employee_edit_privilege do |emp|
    link I18n.t('edit_privilege_text'), {:controller=>"employee",:action=>"edit_privilege",:id=>emp.id}
    parent :employee_profile,emp,emp.user
  end

  crumb :employee_admission4 do |emp|
    link I18n.t('select_reporting_manager'), {:controller=>"employee",:action=>"admission4",:id=>emp.id}
    parent :employee_profile,emp,emp.user
  end

  crumb :employee_payroll_and_payslips do
    link I18n.t('payroll_and_payslips'), {:controller=>"employee",:action=>"payroll_and_payslips"}
    parent :employee_hr
  end

  crumb :payroll_categories_index do
    link I18n.t('payroll_categories'), {:controller=>"payroll_categories",:action=>"index"}
    parent :employee_payroll_and_payslips
  end

  crumb :payroll_categories_new do
    link I18n.t('create_payroll_category').titleize, {:controller=>"payroll_categories",:action=>"new"}
    parent :payroll_categories_index
  end

  crumb :payroll_categories_create do
    link I18n.t('create_payroll_category').titleize, {:controller=>"payroll_categories",:action=>"create"}
    parent :payroll_categories_index
  end

  crumb :payroll_categories_show do |category|
    link shorten_string(category.name, 20), {:controller=>"payroll_categories",:action=>"show",:id=>category.id}
    parent :payroll_categories_index
  end

  crumb :payroll_categories_edit do |category|
    link I18n.t('edit_payroll_category').titleize, {:controller=>"payroll_categories",:action=>"edit",:id=>category.id}
    parent :payroll_categories_show, category
  end

  crumb :payroll_groups_edit do |group|
    link I18n.t('edit'), {:controller=>"payroll_groups",:action=>"edit",:id=>group.id}
    parent :payroll_groups_show, group, Authorization.current_user
  end

  crumb :payroll_groups_index do
    link I18n.t('payroll_groups').titleize, {:controller=>"payroll_groups",:action=>"index"}
    parent :employee_payroll_and_payslips
  end

  crumb :payroll_groups_show do |group|
    link I18n.t('view_payroll_group').titleize, {:controller=>"payroll_groups",:action=>"show",:id=>group.id}
    parent :payroll_groups_index
  end
  crumb :payroll_groups_new do
    link I18n.t('create_payroll_group').titleize, {:controller=>"payroll_group",:action=>"new"}
    parent :payroll_groups_index
  end

  crumb :payroll_groups_create do
    link I18n.t('create_payroll_group'), {:controller=>"payroll_group",:action=>"new"}
    parent :payroll_groups_index
  end

  crumb :employee_payslips_payslip_for_payroll_group do
    link I18n.t('payslip_for_payroll_group'), {:controller=>"employee_payslips",:action=>"payslip_for_payroll_group"}
    parent :employee_payroll_and_payslips
  end

  crumb :employee_payslips_rejected_payslips do |list|
    link I18n.t('rejected_payslips'), {:controller=>"employee_payslips",:action=>"rejected_payslips", :id => list.first.id, :start_date => list.last.first, :end_date => list.last.last}
    parent :employee_payslips_view_past_payslips, list.first, Authorization.current_user
  end

  crumb :employee_payslips_edit_payslip_rejected_payslips do |list|
    link I18n.t('edit_payslip').titleize, {:controller=>"employee_payslips",:action=>"edit_payslip"}
    parent :employee_payslips_rejected_payslips, list, Authorization.current_user
  end

  crumb :employee_payslips_payslip_for_employees do
    link I18n.t('payslip_for_employees'), {:controller=>"employee_payslips",:action=>"payslip_for_employees"}
    parent :employee_payroll_and_payslips
  end

  crumb :employee_payslips_payslip_for_employees_archived do
    link I18n.t('archived_employee_payslips'), {:controller=>"employee_payslips",:action=>"payslip_for_employees", :archived => 1}
    parent :employee_payroll_and_payslips
  end

  crumb :update_payroll_payslip_for_employees do |collection|
    link "#{I18n.t('update_payroll')} - #{collection.last.first_name}", {:controller=>"payroll",:action=>"create_employee_payroll", :id => collection.first.id, :employee_id => collection.last.id}
    parent :employee_payslips_payslip_for_employees
  end

  crumb :employee_payslips_generate_payslips do |list|
    link I18n.t('generate_payslips'), {:controller=>"employee_payslips",:action=>"generate_payslips", :id => list.first.id, :start_date => list.last[0], :end_date => list.last[1]}
    parent :employee_payslips_payslip_for_payroll_group
  end

  crumb :employee_payslips_generate_all_payslips do |list|
    link I18n.t('generate_all_payslips'), {:controller=>"employee_payslips",:action=>"generate_all_payslips", :id => list.first.id, :start_date => list.last[0], :end_date => list.last[1]}
    parent :employee_payslips_generate_payslips , list
  end

  crumb :employee_payslips_generate_employee_payslip do |employee|
    link I18n.t('generate_employee_payslip'), {:controller=>"employee_payslips",:action=>"generate_employee_payslip", :employee_id => employee.id}
    parent :employee_payslips_payslip_for_employees
  end

  crumb :employee_payslips_create_employee_wise_payslip do
    link I18n.t('generate_employee_payslip'), {:controller=>"employee_payslips",:action=>"generate_employee_payslip"}
    parent :employee_payslips_payslip_for_employees
  end

  crumb :employee_payslips_view_employee_past_payslips do |employee|
    link "#{I18n.t('generated_payslips')} - #{shorten_string(employee.first_name, 10)}", {:controller=>"employee_payslips",:action=>"view_employee_past_payslips", :employee_id => employee.id}
    parent :employee_payslips_payslip_for_employees
  end

  crumb :employee_payslips_view_employee_past_payslips_archived do |employee|
    link "#{I18n.t('generated_payslips')} - #{shorten_string(employee.first_name, 10)}", {:controller=>"employee_payslips",:action=>"view_employee_past_payslips", :employee_id => employee.id, :archived => 1}
    parent :employee_payslips_payslip_for_employees_archived
  end

  crumb :past_payslips_view_payroll do |list|
    link I18n.t('view_payroll').titleize, {:controller => 'payroll', :action => 'show', :id => list.first.id, :from => 'past_payslips', :emp_id => list.last.id}
    parent :employee_payslips_view_employee_past_payslips, list.last, Authorization.current_user
  end

  crumb :past_payslips_archived_view_payroll do |list|
    link I18n.t('view_payroll').titleize, {:controller => 'payroll', :action => 'show', :id => list.first.id, :from => 'past_payslips_archived', :emp_id => list.last.id}
    parent :employee_payslips_view_employee_past_payslips_archived, list.last, Authorization.current_user
  end

  crumb :update_payroll_past_payslips do |list|
    link I18n.t('update_payroll'), {:controller=>"payroll",:action=>"create_employee_payroll", :id => list.first.id, :employee_id => list.last.id, :from => 'past_payslips'}
    parent :past_payslips_view_payroll, list, Authorization.current_user
  end

  crumb :employee_payslips_view_past_payslips do |payroll_group|
    link I18n.t('generated_payslips'), {:controller=>"employee_payslips",:action=>"view_past_payslips", :id => payroll_group.id}
    parent :employee_payslips_payslip_for_payroll_group
  end

  crumb :employee_payslips_view_payslip do |employee_payslip|
    link I18n.t('view_payslip'), {:controller=>"employee_payslips",:action=>"view_payslip", :id => employee_payslip.last.id}
    parent :employee_payslips_view_employee_past_payslips, employee_payslip.first, Authorization.current_user
  end

  crumb :employee_payslips_view_payslip_archived do |employee_payslip|
    link I18n.t('employee_payslip').titleize, {:controller=>"employee_payslips",:action=>"view_payslip", :id => employee_payslip.last.id, :from  => 'employee_payslips_archived'}
    parent :employee_payslips_view_employee_past_payslips_archived, employee_payslip.first, Authorization.current_user
  end

  crumb :payroll_groups_assign_employees do |group|
    link I18n.t('assign_employees').titleize, {:controller=>"payroll",:action=>"assign_employees", :id => group.id}
    parent :payroll_groups_assigned_employees, group, Authorization.current_user
  end

  crumb :payroll_groups_assigned_employees do |group|
    link I18n.t('employees'), {:controller=>"payroll",:action=>"assigned_employees", :id => group.id}
    parent :payroll_groups_show, group, Authorization.current_user
  end

  crumb :assigned_employee_view_payroll do |list|
    group = PayrollGroup.find(list.first.id)
    link I18n.t('view_payroll').titleize, {:controller => 'payroll', :action => 'show', :id => list.first.id, :emp_id => list.last.id, :from => 'assigned_employees'}
    parent :payroll_groups_assigned_employees, group, Authorization.current_user
  end

  crumb :removing_from_group do |list|
    group = PayrollGroup.find(list.last.id)
    link I18n.t('pending_or_rejected_payslips'), {:controller=>"employee_payslips",:action=>"view_employee_pending_payslips", :employee_id => list.first.id, :from => "assigned_employees"}
    parent :payroll_groups_assigned_employees, group, Authorization.current_user
  end

  crumb :adding_to_group do |list|
    group = PayrollGroup.find(list.last.id) unless list.last.nil?
    link I18n.t('pending_or_rejected_payslips'), {:controller => "employee_payslips", :action => "view_employee_pending_payslips", :employee_id => list.first.id, :from => "assign_employees"}
    if group.present?
      parent :payroll_groups_assign_employees, group, Authorization.current_user
    else
      parent :employee_profile, list.first
    end
  end

  crumb :employee_profile_pending_payslips do |employee|
    link I18n.t('pending_or_rejected_payslips'), {:controller => "employee_payslips", :action => "view_employee_pending_payslips", :employee_id => employee.id, :from => "profile"}
    parent :employee_change_to_former, employee
  end

  crumb :employee_payslips_assigned_employees do |list|
    link I18n.t('employee_payslip').titleize, {:controller=>"employee_payslips",:action=>"view_payslip", :id => list.first.id, :from => "assigned_employees"}
    parent :removing_from_group, list.last, Authorization.current_user
  end

  crumb :employee_payslips_assign_employees do |list|
    link I18n.t('employee_payslip').titleize, {:controller=>"employee_payslips",:action=>"view_payslip", :id => list.first.id, :from => "assign_employees"}
    parent :adding_to_group, list.last, Authorization.current_user
  end

  crumb :employee_payslips_edit_assigned_employees do |list|
    link I18n.t('edit_payslip').titleize, {:controller=>"employee_payslips",:action=>"edit_payslip", :id => list.first.id, :from => "assigned_employees"}
    parent :removing_from_group, list.last, Authorization.current_user
  end

  crumb :employee_payslips_generate_employee_payslip_outdated_employees do |list|
    group = PayrollGroup.find(list.first.first.id)
    link I18n.t('generate_employee_payslip'), {:controller=>"employee_payslips",:action=>"generate_employee_payslip", :start_date => list.last.first,:end_date => list.last.last, :employee_id => list.first.last, :from => "view_outdated_employees"}
    parent :employee_payslips_view_outdated_employees, [group,[list.last.first, list.last.last]]
  end

  crumb :employee_payslips_payslip_generation_list_view_payslip do |list|
    link I18n.t('employee_payslip').titleize, {:controller=>"employee_payslips",:action=>"view_payslip"}
    parent :employee_payslips_payslip_generation_list, list, Authorization.current_user
  end

  crumb :employee_payslips_payslip_generation_list_view_payslip_past do |list|
    link I18n.t('employee_payslip').titleize, {:controller=>"employee_payslips",:action=>"view_payslip"}
    parent :employee_payslips_payslip_generation_list_past, list, Authorization.current_user
  end

  crumb :employee_payslips_generate_employee_payslip_lop_employees do |list|
    group = PayrollGroup.find(list.first.first.id)
    link I18n.t('generate_employee_payslip'), {:controller=>"employee_payslips",:action=>"generate_employee_payslip", :start_date => list.last.first,:end_date => list.last.last, :employee_id => list.first.last, :from => "view_employees_with_lop"}
    parent :employee_payslips_view_employees_with_lop, [group,[list.last.first, list.last.last]]
  end

  crumb :employee_payslips_edit_payslip_generation_list do |list|
    link I18n.t('edit_payslip').titleize, {:controller=>"employee_payslips",:action=>"edit_pasylip", :id => list.first.id,:start_date => list.last.first,:end_date => list.last.last}
    parent :employee_payslips_payslip_generation_list, list, Authorization.current_user
  end

  crumb :employee_payslips_past_payslips_edit_payslip do |list|
    link I18n.t('edit_payslip').titleize, {:controller=>"employee_payslips",:action=>"edit_payslip", :id => list.first.id,:start_date => list.last.first,:end_date => list.last.last}
    parent :employee_payslips_payslip_generation_list_past, list, Authorization.current_user
  end

  crumb :employee_payslips_generate_employee_payslip_regular_employees do |list|
    group = PayrollGroup.find(list.first.id)
    link I18n.t('generate_employee_payslip'), {:controller=>"employee_payslips",:action=>"view_regular_employees", :id => list.first.id,:start_date => list.last.first,:end_date => list.last.last}
    parent :employee_payslips_view_regular_employees, [group,[list.last.first, list.last.last]]
  end




  crumb :employee_payslips_edit_assign_employees do |list|
    link I18n.t('edit_payslip'), {:controller=>"employee_payslips",:action=>"edit_payslip", :id => list.first.id, :from => "assign_employees"}
    parent :adding_to_group, list.last, Authorization.current_user
  end

  crumb :payroll_groups_create_employee_payroll do |collection|
    link I18n.t('employee_payroll').titleize, {:controller=>"payroll",:action=>"create_employee_payroll", :id => collection.first.id, :employee_id => collection.last.id}
    parent :payroll_groups_assign_employees, collection.first, Authorization.current_user
  end

  crumb :edit_assigned_employee_payroll do |collection|
    link I18n.t('employee_payroll').titleize, {:controller=>"payroll",:action=>"create_employee_payroll", :id => collection.first.id, :employee_id => collection.last.id}
    parent :assigned_employee_view_payroll, collection, Authorization.current_user
  end

  crumb :employee_profile_edit_employee_payroll do |collection|
    link I18n.t('edit_employee_payroll'), {:controller=>"payroll",:action=>"create_employee_payroll", :id => collection.first.id, :employee_id => collection.last.id}
    parent :employee_profile, collection.last, Authorization.current_user
  end

  crumb :payroll_groups_working_day_settings do
    link I18n.t('working_day_settings').titleize, {:controller=>"payroll_groups",:action=>"working_day_settings"}
    parent :employee_settings
  end

  crumb :payroll_groups_update_working_day_settings do
    link I18n.t('working_day_settings').titleize, {:controller=>"payroll_groups",:action=>"working_day_settings"}
    parent :employee_settings
  end

  crumb :hr_payslip_report do
    link I18n.t('employee_payslip_report'), {:controller=>"finance",:action=>"view_monthly_payslip", :hr => 1}
    parent :employee_payroll_and_payslips
  end

  crumb :hr_payslip_reports_view_payslip do |employee_payslip|
    link I18n.t('employee_payslip').titleize, {:controller=>"employee_payslips",:action=>"view_payslip", :id => employee_payslip.id, :hr => 1, :from => "payslip_reports"}
    parent :hr_payslip_report
  end

  crumb :view_outdated_employees_edit_payroll do |collection|
    link I18n.t('update_payroll'), {:controller=>"payroll",:action=>"create_employee_payroll", :id => collection.first.first.id, :employee_id => collection.first.last.id, :start_date => collection.last.first, :end_date => collection.last.last, :from => 'view_outdated_employees'}
    parent :employee_payslips_generate_employee_payslip_outdated_employees, collection, Authorization.current_user
  end

  crumb :generate_employee_payslip_edit_payroll do |list|
    link I18n.t('update_payroll'), {:controller=>"payroll",:action=>"create_employee_payroll", :id => list.first.id, :employee_id => list.last.id, :from => 'generate_employee_payslip'}
    parent :employee_payslips_generate_employee_payslip, list.last, Authorization.current_user
  end

  crumb :view_employees_with_lop_edit_payroll do |collection|
    link I18n.t('update_payroll'), {:controller=>"payroll",:action=>"create_employee_payroll", :id => collection.first.first.id, :employee_id => collection.first.last.id, :start_date => collection.last.first, :end_date => collection.last.last, :from => 'view_outdated_employees'}
    parent :employee_payslips_generate_employee_payslip_lop_employees, collection, Authorization.current_user
  end

  crumb :hr_reports_index do
    link I18n.t('advanced_payslip_reports'), {:controller=>"hr_reports",:action=>"index", :hr => 1}
    parent :employee_payroll_and_payslips
  end


  crumb :hr_reports_report do
    link I18n.t('generate_reports'), {:controller=>"hr_reports",:action=>"report", :hr => 1}
    parent :hr_reports_index
  end

  crumb :hr_reports_template do
    link I18n.t('reports_text'), {:controller=>"hr_reports",:action=>"template", :hr => 1}
    parent :hr_reports_index
  end

  crumb :payroll_settings do
    link I18n.t('payroll_settings').titleize, {:controller=>"payroll",:action=>"settings"}
    parent :employee_settings
  end

  crumb :payroll_groups_lop_settings do |group|
    link I18n.t('lop_settings'), {:action => 'lop_settings', :controller => 'payroll_groups', :id => group.id}
    parent :payroll_groups_show, group, Authorization.current_user
  end

  crumb :leave_groups_index do
    link I18n.t('leave_groups').titleize, {:controller=>"leave_groups",:action=>"index"}
    parent :employee_settings
  end

  crumb :leave_groups_show do |leave_group|
    link leave_group.name, {:controller=>"leave_groups",:action=>"show", :id => leave_group.id}
    parent :leave_groups_index
  end

  crumb :leave_groups_add_employees do |leave_group|
    link I18n.t('add_employees'), {:controller=>"leave_groups",:action=>"add_employees", :id => leave_group.id}
    parent :leave_groups_show, leave_group
  end

  crumb :leave_groups_manage_employees do |leave_group|
    link I18n.t('manange_employees'), {:controller=>"leave_groups",:action=>"manage_employees", :id => leave_group.id}
    parent :leave_groups_show, leave_group
  end

  crumb :leave_groups_manage_leave_group do |emp|
    link I18n.t('add_leave_group'), {:controller=>"leave_groups",:action=>"manage_leave_group",:id=>emp.id}
    parent :employee_profile,emp
  end

  ########################################
  #User Search
  ########################################

  crumb :user_index do
    link I18n.t('find_user'), {:controller=>"user",:action=>"index"}
  end

  crumb :user_all_users do
    link I18n.t('view_all'), {:controller=>"user",:action=>"all"}
    parent :user_index
  end

  crumb :user_create do
    link I18n.t('add_user'), {:controller=>"user",:action=>"create"}
    parent :user_index
  end

  crumb :user_profile do|this_user|
    link this_user.username, {:controller=>"user",:action=>"profile",:id=>this_user.username}
    parent :user_index
  end

  crumb :user_user_change_password do|this_user|
    link I18n.t('change_password'), {:controller=>"user",:action=>"user_change_password",:id=>this_user.username}
    parent :user_profile,this_user
  end

  crumb :user_change_password do|this_user|
    link I18n.t('change_password'), {:controller=>"user",:action=>"change_password",:id=>this_user.username}
    parent :user_profile,this_user
  end

  crumb :user_edit_privilege do|this_user|
    link I18n.t('edit_privilege_text'), {:controller=>"user",:action=>"edit_privilege",:id=>this_user.username}
    parent :user_profile,this_user
  end

  ########################################
  #Student Search
  ########################################

  crumb :student_index do
    link I18n.t('students'), {:controller=>"student",:action=>"index"}
  end
  crumb :student_profile do|student|
    link student.full_name, {:controller=>"student",:action=>"profile",:id=>student.id}
    parent :student_index
  end
  crumb :student_reports do|student|
    link I18n.t('report_center'), {:controller=>"student",:action=>"reports",:id=>student.id}
    parent :student_profile, student,student.user
  end
  crumb :batch_reports do|student|
    link I18n.t('previous_batch_reports'), {:controller=>"assessment_reports", :action=>"batch_reports", :id=>student.id}
    parent :student_reports, student
  end
  crumb :student_guardians do|student|
    link I18n.t('guardians_text'), {:controller=>"student",:action=>"guardians",:id=>student.id}
    parent :student_profile, student,student.user
  end
  crumb :student_transcript_st_view do|student|
    link "Transcript Report", {:controller=>"exam",:action=>"student_transcript",:transcript=>{:batch_id=>student.batch_id},:student_id=>student.id,:flag=>"1"}
    parent :student_reports, student,student.user
  end
  crumb :student_transcript_st_ar_view do|student|
    link "Transcript Report", {:controller=>"exam",:action=>"student_transcript",:transcript=>{:batch_id=>student.batch_id},:student_id=>student.id,:flag=>"1"}
    parent :archived_student_reports, student,student.user
  end
  crumb :student_view_all do
    link I18n.t('view_all'), {:controller=>"student",:action=>"view_all"}
    parent :student_index
  end

  crumb :student_advanced_search do
    link I18n.t('advanced_search_text'), {:controller=>"student",:action=>"advanced_search"}
    parent :student_index
  end

  crumb :student_edit do|stud|
    link I18n.t('general_details_edit'), {:controller=>"student",:action=>"edit",:id=>stud.id}
    parent :student_profile,stud,stud.user
  end

  crumb :student_add_guardian do|stud|
    link I18n.t('add_guardian'), {:controller=>"student",:action=>"add_guardian",:id=>stud.id}
    parent :student_profile,stud,stud.user
  end

  crumb :student_admission3_1 do|stud|
    link I18n.t('immediate_contact'), {:controller=>"student",:action=>"admission3_1",:id=>stud.id}
    parent :student_profile,stud,stud.user
  end

  crumb :student_admission4 do|stud|
    link I18n.t('additional_details'), {:controller=>"student",:action=>"admission4",:id=>stud.id}
    parent :student_profile,stud,stud.user
  end

  crumb :student_previous_data_from_profile do|stud|
    link I18n.t('previous_educational_details'), {:controller=>"student",:action=>"previous_data_from_profile",:id=>stud.id}
    parent :student_profile,stud,stud.user
  end

  crumb :student_show_previous_details do|stud|
    link I18n.t('show_previous_details'), {:controller=>"student",:action=>"show_previous_details",:id=>stud.id}
    parent :student_profile,stud,stud.user
  end

  crumb :student_previous_data_edit do|stud|
    link I18n.t('edit_previous_details'), {:controller=>"student",:action=>"previous_data_edit",:id=>stud.id}
    parent :student_profile,stud,stud.user
  end

  crumb :student_attendance_student do|stud|
    link I18n.t('current_attendance_report'), {:controller=>"student_attendance",:action=>"student",:id=>stud.id}
    parent :student_reports,stud
  end

  crumb :student_admission1_2 do|stud|
    link I18n.t('sibling'), {:controller=>"student",:action=>"admission1_2",:id=>stud.id}
    parent :student_profile,stud,stud.user
  end

  crumb :student_email do|stud|
    link I18n.t('send_email'), {:controller=>"student",:action=>"email",:id=>stud.id}
    parent :student_profile,stud,stud.user
  end

  crumb :student_remove do|stud|
    link I18n.t('remove'), {:controller=>"student",:action=>"remove",:id=>stud.id}
    parent :student_profile,stud,stud.user
  end

  crumb :student_change_to_former do|stud|
    link I18n.t('archive_student'), {:controller=>"student",:action=>"change_to_former",:id=>stud.id}
    parent :student_remove,stud
  end

  crumb :student_delete do|stud|
    link I18n.t('delete_student'), {:controller=>"student",:action=>"delete",:id=>stud.id}
    parent :student_remove,stud
  end

  crumb :student_fees do|stud|
    if stud.class.name == 'Student'
      link I18n.t('fees_text'), {:controller=>"student",:action=>"fees",:id=>stud.id}
      parent :student_profile,stud, stud.user
    else
      link I18n.t('fees_text'), {:controller=>"archived_student",:action=>"fees",:id=>stud.id}
      parent :archived_student_profile,stud
    end
  end

  crumb :student_fee_details do|list|
    link list.last.name, {:controller=>"student",:action=>"fee_details",:id=>list.last.id}
    parent :student_fees,list.first
  end

  crumb :archived_student_profile do|stud|
    link stud.full_name, {:controller=>"archived_student",:action=>"profile",:id=>stud.id}
    parent :student_index
  end

  crumb :archived_student_reports do|stud|
    link I18n.t('report_center'), {:controller=>"archived_student",:action=>"reports",:id=>stud.id}
    parent :archived_student_profile,stud
  end

  crumb :archived_student_generated_report3 do|list|
    link list.last.name, {:controller=>"archived_student",:action=>"generated_report3",:id=>list.last.id}
    parent :archived_student_reports,list.first
  end

  crumb :archived_student_guardians do|stud|
    link I18n.t('guardians_text'), {:controller=>"archived_student",:action=>"guardians",:id=>stud.id}
    parent :archived_student_profile,stud
  end

  crumb :archived_student_student_report do|stud|
    link I18n.t('archived_attendance_report'), {:controller=>"archived_student",:action=>"student_report",:id=>stud.id}
    parent :archived_student_reports,stud
  end

  crumb :archived_student_generated_report do|list|
    link I18n.t('generated_report'), {:controller=>"archived_student",:action=>"generated_report",:exam_group=>list.last,:student=>list.first}
    parent :archived_student_reports,list.first
  end

  crumb :student_edit_guardian do|list|
    link I18n.t('edit_guardian')+ " - "+list.last.first_name_was, {:controller=>"student",:action=>"edit_guardian",:id=>list.last.id}
    parent :student_guardians,list.first
  end

  crumb :student_attendance_student_report do|list|
    link I18n.t('archived_attendance_report'), {:controller=>"student_attendance",:action=>"student_report",:id=>list.last.id}
    parent :student_reports,list.first
  end

  ########################################
  #Student Admission
  ########################################

  crumb :student_admission1 do
    link I18n.t('student_admission'), {:controller=>"student",:action=>"admission1"}
  end
  crumb :student_previous_data do|student|
    link I18n.t('previous_details'), {:controller=>"student",:action=>"previous_data",:id=>student.id}
    parent :student_profile,student,student.user
  end
  crumb :student_admission2 do|student|
    link I18n.t('parent_guardian_details'), {:controller=>"student",:action=>"admission2",:id=>student.id}
    parent :student_profile,student,student.user
  end
  crumb :student_admission3 do|student|
    link I18n.t('emergency_contact'), {:controller=>"student",:action=>"admission3",:id=>student.id}
    parent :student_profile,student,student.user
  end

  crumb :student_roll_number_index do
    link I18n.t('manage_student_roll_number'), {:controller=>"student_roll_number",:action=>"index"}
    parent :configuration_index
  end

  crumb :student_roll_number_view_batches do |course|
    link course.full_name, {:controller=>"student_roll_number",:action=>"view_batches", :id => course.id}
    parent :student_roll_number_index
  end

  crumb :student_roll_number_set_roll_numbers do |batch|
    link batch.full_name, {:controller=>"student_roll_number",:action=>"set_roll_numbers", :id => batch.id}
    parent :student_roll_number_view_batches, batch.course,Authorization.current_user
  end

  ########################################
  #Settings Module
  ########################################

  crumb :configuration_index do
    link I18n.t('configuration_text'), {:controller=>"configuration",:action=>"index"}
  end
  crumb :configuration_settings do
    link I18n.t('settings'), {:controller => "configuration", :action => "settings"}
    parent :configuration_index
  end
  crumb :courses_index do
    link I18n.t('courses_text'), {:controller => "courses", :action => "index"}
    parent :configuration_index
  end
  crumb :courses_manage_course do
    link I18n.t('manage_course'), {:controller => "courses", :action => "manage_course"}
    parent :courses_index
  end
  crumb :courses_manage_batches do
    link I18n.t('manage_batch'), {:controller => "courses", :action => "manage_batches"}
    parent :courses_index
  end
  crumb :batch_transfers_index do
    link I18n.t('batch_transfer'), {:controller => "batch_transfers", :action => "index"}
    parent :courses_manage_batches
  end
  crumb :batch_transfers_show do |batch|
    link batch.full_name, {:controller => "batch_transfers", :action => "show", :id  => batch.id}
    parent :batch_transfers_index
  end
  crumb :batch_transfers_graduation do |batch|
    link batch.full_name, {:controller => "batch_transfers", :action => "graduation", :id  => batch.id}
    parent :batch_transfers_index
  end
  crumb :revert_batch_transfers_index do
    link I18n.t('revert_batch_transfer'), {:controller => "revert_batch_transfers", :action => "index"}
    parent :courses_manage_batches
  end
  crumb :revert_batch_transfers_revert_transfer do
    link I18n.t('revert_batch_transfer'), {:controller => "revert_batch_transfers", :action => "index"}
    parent :courses_manage_batches
  end
  crumb :courses_new do
    link I18n.t('new_text'), {:controller => "courses", :action => "new"}
    parent :courses_manage_course
  end
  crumb :courses_create do
    link I18n.t('new_text'), {:controller => "courses", :action => "new"}
    parent :courses_manage_course
  end
  crumb :courses_edit do |course|
    link I18n.t('edit_text'), {:controller => "courses", :action => "edit", :id => course.id}
    parent :courses_show, course
  end
  crumb :courses_show do |course|
    link course.full_name, {:controller => "courses", :action => "show", :id => course.id}
    parent :courses_manage_course
  end
  crumb :batches_new do |course|
    link I18n.t('new_batch'),{:controller => "batches", :action => "new"}
    parent :courses_show, course
  end
  crumb :batches_show do |batch|
    link "#{I18n.t('batch')} #{batch.name_was}",{:controller => "batches", :action => "show", :id => batch.id,:course_id => batch.course.id}
    parent :courses_show, batch.course
  end
  crumb :batches_batch_summary do |batch|
    link "#{I18n.t('batch_summary')}",{:controller => "batches", :action => "batch_summary"}
  end

  crumb :batches_edit do |batch|
    link I18n.t('edit_text'),{:controller => "batches", :action => "edit",:id => batch.id}
    parent :batches_show, batch, Authorization.current_user
  end
  crumb :batches_update do |batch|
    link I18n.t('edit_text'),{:controller => "batches", :action => "edit",:id => batch.id}
    parent :batches_show, batch, Authorization.current_user
  end
  crumb :batches_assign_tutor do |batch|
    link I18n.t('assign_tutor'),{:controller => "batches", :action => "assign_tutor"}
    parent :batches_show, batch, Authorization.current_user
  end
  crumb :batch_transfers_subject_transfer do |batch|
    link I18n.t('assign_subject'),{:controller => "batch_transfers", :action => "subject_transfer"}
    parent :batches_show, batch, Authorization.current_user
  end
  crumb :subjects_index do
    link I18n.t('subjects_text'), {:controller => "subjects", :action => "index"}
    parent :configuration_index
  end
  crumb :subjects_import_subjects do |batch|
    link I18n.t('import_subjects'), {:controller => "subjects", :action => "import_subjects", :id => batch.id }
    parent :subjects_index
  end
  crumb :elective_groups_index do |batch|
    link I18n.t('elective_groups_text'),{:controller => "elective_groups", :action => "index",:batch_id => batch.id}
    parent :batches_show, batch, Authorization.current_user
  end
  crumb :elective_groups_show do |elective_group|
    link elective_group.name_was,{:controller => "elective_groups", :action => "show",:id => elective_group.id,:batch_id => elective_group.batch.id}
    parent :elective_groups_index, elective_group.batch
  end
  crumb :elective_groups_edit do |elective_group|
    link I18n.t('edit_text'),{:controller => "elective_groups", :action => "edit",:id => elective_group.id,:batch_id => elective_group.batch.id}
    parent :elective_groups_show, elective_group
  end
  crumb :elective_groups_new do |batch|
    link I18n.t('new_elective'),{:controller => "elective_groups", :action => "new",:batch_id => batch.id}
    parent :batches_show, batch, Authorization.current_user
  end

  crumb :student_assigned_elective_subjects do |batch|
    link I18n.t('assigned_electives'),{:controller => "student", :action => "assigned_elective_subjects",:id => batch.id}
    parent :subjects_index
  end

  crumb :student_my_subjects do |student|
    link I18n.t('my_subjects'),{:controller => "student", :action => "my_subjects", :id => student.id}
    parent :student_profile, student,student.user
  end

  crumb :student_activities do |student|
    link I18n.t('activities'),{:controller => "student", :action => "activities", :id => student.id}
    parent :student_profile, student, student.user
  end

  crumb :employee_activities do |employee|
    link I18n.t('activities'),{:controller => "employee", :action => "activities", :id => employee.id}
    parent :employee_profile, employee, employee.user
  end

  crumb :student_electives do |elective_subject|
    link elective_subject.name,{:controller => "student", :action => "electives",:id => elective_subject.elective_group.batch.id,:id2 => elective_subject.id}
    parent :elective_groups_show, elective_subject.elective_group
  end
  crumb :courses_grouped_batches do |course|
    link I18n.t('grouped_batches'),{:controller => "courses", :action => "grouped_batches", :id => course.id}
    parent :courses_show, course
  end
  crumb :courses_assign_subject_amount do |course|
    link I18n.t('assign_subject_amount'),{:controller => "courses", :action => "assign_subject_amount", :id => course.id}
    parent :courses_show, course
  end
  crumb :courses_edit_subject_amount do |subject_amount|
    link subject_amount.code,{:controller => "courses", :action => "edit_subject_amount", :subject_amount_id => subject_amount.id}
    parent :courses_assign_subject_amount, subject_amount.course
  end
  crumb :student_categories do
    link I18n.t('student_categories'), {:controller => "student", :action => "categories"}
    parent :configuration_index
  end
  crumb :student_add_additional_details do
    link I18n.t('additional_detail'), {:controller => "student", :action => "add_additional_details"}
    parent :configuration_index
  end
  crumb :student_edit_additional_details do
    link I18n.t('additional_detail'), {:controller => "student", :action => "edit_additional_details"}
    parent :configuration_index
  end
  crumb :sms_index do
    link I18n.t('sms_text'), {:controller => "sms", :action => "index"}
  end
  crumb :sms_settings do
    link I18n.t('settings'), {:controller => "sms", :action => "settings"}
    parent :sms_index
  end
  crumb :sms_send_sms do
    link I18n.t('send_sms'), {:controller => "sms", :action => "send_sms"}
    parent :sms_index
  end
  crumb :sms_students do
    link I18n.t('student_text'), {:controller => "sms", :action => "students"}
    parent :sms_index
  end
  crumb :sms_batches do
    link I18n.t('batches_text'), {:controller => "sms", :action => "batches"}
    parent :sms_index
  end
  crumb :sms_employees do
    link I18n.t('employees'), {:controller => "sms", :action => "employees"}
    parent :sms_index
  end
  crumb :sms_departments do
    link I18n.t('departments'), {:controller => "sms", :action => "departments"}
    parent :sms_index
  end
  crumb :sms_show_sms_messages do
    link I18n.t('sms_logs'), {:controller => "sms", :action => "show_sms_messages"}
    parent :sms_index
  end
  crumb :sms_birthday_sms do
    link I18n.t('birthday_sms'), {:controller => "sms", :action => "show_sms_messages"}
    parent :sms_index
  end
  crumb :sms_show_sms_logs do
    link I18n.t('sms_logs'), {:controller => "sms", :action => "show_sms_logs"}
    parent :sms_show_sms_messages, nil, SmsSetting.find_by_settings_key("ApplicationEnabled")
  end
  crumb :custom_words_index do
    link I18n.t('custom_words_text'), {:controller => "custom_words", :action => "index"}
    parent :configuration_index
  end

  crumb :custom_words_create do
    link I18n.t('custom_words_text'), {:controller => "custom_words", :action => "index"}
    parent :configuration_index
  end

  ########################################
  #News Module
  ########################################
  crumb :news_index do
    link I18n.t('news_text'), {:controller => "news", :action => "index"}
  end
  crumb :news_all do
    link I18n.t('view_all'), {:controller => "news", :action => "all"}
    parent :news_index
  end
  crumb :news_view do |news|
    link shorten_string(news.title_was,20), {:controller => "news", :action => "view",:id => news.id}
    parent :news_index
  end
  crumb :news_add do
    link I18n.t('add'), {:controller => "news", :action => "add"}
    parent :news_index
  end
  crumb :news_new do
    link I18n.t('add'), {:controller => "news", :action => "new"}
    parent :news_index
  end
  crumb :news_create do
    link I18n.t('add'), {:controller => "news", :action => "new"}
    parent :news_index
  end
  crumb :news_edit do |news|
    link I18n.t('edit_text'), {:controller => "news", :action => "edit"}
    parent :news_view, news
  end

  ########################################
  #Attendance Module
  ########################################
  crumb :student_attendance_index do
    link I18n.t('attendance'), {:controller => "student_attendance", :action => "index"}
  end
  crumb :attendances_index do
    link I18n.t('attendance_register'), {:controller => "attendance", :action => "index"}
    parent :student_attendance_index
  end
  crumb :attendance_reports_index do
    link I18n.t('attendance_report'), {:controller => "attendance_reports", :action => "index"}
    parent :student_attendance_index
  end
  crumb :attendance_reports_consolidated_report do
    link I18n.t('consolidated_subjectwise_report'), {:controller=>"attendance_reports",:action=>"consolidated_report"}
    parent :attendance_reports_index
  end
  crumb :attendance_reports_filter do
    link I18n.t('filtered_report'), {:controller => "attendance_reports", :action => "filter"}
    parent :attendance_reports_index
  end

  crumb :attendance_reports_student_details do |student|
    link student.full_name, {:controller => "attendance_reports", :action => "student_details", :id => student.id}
    parent :attendance_reports_index
  end

  crumb :attendance_reports_day_wise_report do
    link I18n.t('day_wise_report'), {:controller => "attendance_reports", :action => "day_wise_report"}
    parent :student_attendance_index
  end

  crumb :attendance_reports_daily_report_batch_wise do
    link "#{I18n.t('day_wise_report')} - #{I18n.t('batch')}", {:controller => "attendance_reports", :action => "daily_report_batch_wise"}
    parent :attendance_reports_day_wise_report
  end

  crumb :attendances_notification_status do
    link I18n.t('notification_status'), {:controller => "attendance", :action => "notification_status"}
    parent :student_attendance_index
  end

  crumb :attendance_labels_index do
    link I18n.t('attendance_settings'), {:controller => "attendance_labels", :action => "index"}
    parent :student_attendance_index
  end


  crumb :attendance_labels_edit do
    link I18n.t('edit'), {:controller => "attendance_labels", :action => "edit"}
    parent :attendance_labels_index
  end


  crumb :attendance_labels_update do
    link I18n.t('edit'), {:controller => "attendance_labels", :action => "update"}
    parent :attendance_labels_index
  end

  ########################################
  #Timetable Module
  ########################################

  crumb :timetable_index do
    link I18n.t('timetable_text'), {:controller => "timetable", :action => "index"}
  end
  crumb :timetable_settings do
    link I18n.t('settings'), {:controller => "timetable", :action => "settings"}
    parent :timetable_index
  end
  crumb :timetable_student_view do
    link I18n.t('timetable_view'), {:controller => "timetable", :action => "student_view"}
  end
  crumb :weekday_index do
    link I18n.t('set_weekdays_and_class_timing_set'), {:controller => "weekday", :action => "index"}
    parent :timetable_index
  end
  crumb :class_timing_sets_new_batch_class_timing_set do
    link I18n.t('manage_class_timing_sets'), {:controller => "class_timing_sets", :action => "new_batch_class_timing_set"}
    parent :timetable_index
  end
  crumb :class_timing_sets_index do
    link I18n.t('class_timing_sets'), {:controller => "class_timing_sets", :action => "index"}
    parent :timetable_index
  end
  crumb :class_timing_sets_show do |class_timing_set|
    link class_timing_set.name_was, {:controller => "class_timing_sets", :action => "show", :id => class_timing_set.id}
    parent :class_timing_sets_index
  end
  crumb :class_timing_sets_new do
    link I18n.t('new_text'), {:controller => "class_timing_sets", :action => "new"}
    parent :class_timing_sets_index
  end
  crumb :class_timing_sets_create do
    link I18n.t('new_text'), {:controller => "class_timing_sets", :action => "new"}
    parent :class_timing_sets_index
  end
  crumb :class_timing_sets_edit do |class_timing_set|
    link I18n.t('edit_text'), {:controller => "class_timing_sets", :action => "edit", :id => class_timing_set.id}
    parent :class_timing_sets_show, class_timing_set
  end
  crumb :timetable_work_allotment do
    link I18n.t('work_allotment'), {:controller => "timetable", :action => "work_allotment"}
    parent :timetable_index
  end
  crumb :timetable_manage_work_allocations do |batch|
    link I18n.t('manage_work_allocations'), {:controller => "timetable", :action => "manage_work_allocations"}
    parent :timetable_work_allotment
  end
  crumb :timetable_new_timetable do
    link I18n.t('new_timetable'), {:controller => "timetable", :action => "new_timetable"}
    parent :timetable_manage_timetables
  end
  crumb :timetable_entries_new do |timetable|
    link I18n.t('manage_allocations'), {:controller => "timetable_entries", :action => "new", :timetable_id => timetable.id }
    parent :timetable_manage_allocations, timetable
  end

  crumb :manage_batches_timetables do |timetable|
    link I18n.t('manage_batches_text'), {:controller => "timetable", :action => "manage_batches", :id => timetable.id }
    parent :timetable_update_timetable, timetable
  end

  crumb :timetable_manage_timetables do #|timetable|
    link I18n.t('manage_timetables'), {:controller => "timetable", :action => "manage_timetables" }
    parent :timetable_index
  end

  crumb :timetable_summary do |timetable|
    link I18n.t('timetable_summary_text'), {:controller => "timetable", :action => "summary" }
    parent :timetable_manage_allocations, timetable
  end

  crumb :timetable_manage_allocations do |timetable|
    link I18n.t('timetable_allocations'), {:controller => "timetable", :action => "manage_allocations", :id => timetable.id }
    parent :timetable_manage_timetables, timetable
  end

  crumb :timetable_edit_master do
    link I18n.t('timetable_periods'), {:controller => "timetable", :action => "edit_master"}
    parent :timetable_index
  end
  crumb :timetable_update_timetable do |timetable|
    link "#{format_date(timetable.start_date,:format=>:long)}  -  #{format_date(timetable.end_date,:format=>:long)}", {:controller => "timetable", :action => "update_timetable", :id => timetable.id }
    parent :timetable_manage_timetables
  end
  crumb :timetable_view do
    link I18n.t('timetable_view'), {:controller => "timetable", :action => "view"}
    parent :timetable_index
  end
  crumb :timetable_teachers_timetable do
    link I18n.t('teacher_timetable'), {:controller => "timetable", :action => "teachers_timetable"}
    parent :timetable_index
  end
  crumb :timetable_timetable do
    link I18n.t('institutional_timetable'), {:controller => "timetable", :action => "timetable"}
    parent :timetable_index
  end
  crumb :timetable_tracker_index do
    link I18n.t('timetable_tracker'), {:controller => "timetable_tracker", :action => "index"}
    parent :timetable_index
  end
  crumb :timetable_tracker_class_timetable_swap do
    link I18n.t('swap_timetable_text'), {:controller => "timetable_tracker", :action => "class_timetable_swap"}
    parent :timetable_tracker_index
  end
  crumb :timetable_tracker_swaped_timetable_report do
    link "#{I18n.t('swaped_timetable')} #{I18n.t('report')}", {:controller => "timetable_tracker", :action => "swaped_timetable_report"}
    parent :timetable_tracker_index
  end
  crumb :timetable_employee_timetable do |employee|
    link I18n.t('teacher_timetable'), {:controller => "timetable", :action => "employee_timetable", :id => employee.id}
    parent :employee_profile, employee,employee.user
  end

  crumb :buildings_new do
    link I18n.t('new_text'), {:controller => "buildings", :action => "new"}
    parent :buildings_index
  end

  crumb :buildings_create do
    link I18n.t('new_text'), {:controller => "buildings", :action => "new"}
    parent :buildings_index
  end

  crumb :classrooms_create do
    link I18n.t('new_text'), {:controller => "classrooms", :action => "new"}
    parent :buildings_index
  end

  crumb :classroom_allocations_index do
    link I18n.t('classroom_allocation'), {:controller => "classroom_allocations", :action => "index"}
    parent :timetable_index
  end

  crumb :classroom_allocations_new do
    link I18n.t('new_text'), {:controller => "classroom_allocations", :action => "new"}
    parent :classroom_allocations_index
  end

  crumb :buildings_index do
    link I18n.t('buildings'), {:controller => "buildings", :action => "index"}
    parent :classroom_allocations_index
  end

  crumb :buildings_show do |building|
    link building.name, {:controller => "buildings", :action => "show", :id => building.id }
    parent :buildings_index
  end

  crumb :classrooms_new do
    link I18n.t('new_text'), {:controller => "classrooms", :action => "new"}
    parent :buildings_index
  end

  crumb :buildings_edit do |building|
    link I18n.t('edit_text'), {:controller => "buildings", :action => "edit", :id => building.id}
    parent :buildings_index
  end

  crumb :classrooms_show do |classroom|
    link classroom.name, {:controller => "classrooms", :action => "show", :id => classroom.id }
    parent :buildings_show, classroom.building
  end

  crumb :allocated_classrooms_new do
    link I18n.t('new_text'), {:controller => "allocated_classrooms", :action => "new"}
    parent :classroom_allocations_index
  end

  crumb :classrooms_edit do |classroom|
    link I18n.t('edit_text'), {:controller => "classrooms", :action => "edit", :id => classroom.id }
    parent :buildings_show, classroom.building
  end

  ########################################
  #Examination Module
  ########################################


  crumb :exam_index do
    link I18n.t('exam_text'), {:controller=>"exam",:action=>"index"}
  end
  crumb :exam_report_center do
    link I18n.t('report_center'), {:controller=>"exam",:action=>"report_center"}
    parent :exam_index,Authorization.current_user
  end
  crumb :exam_exam_wise_report do
    link I18n.t('exam_wise_report'), {:controller=>"exam",:action=>"exam_wise_report"}
    parent :exam_report_center
  end
  crumb :exam_generated_report do
    link I18n.t('generated_report'), {:controller=>"exam",:action=>"generated_report"}
    parent :exam_exam_wise_report
  end
  crumb :exam_generated_report_st_view do|list|
    link list.last.name, {:controller=>"exam",:action=>"generated_report",:exam_group =>list.last.id, :student => list.first.id}
    parent :student_reports, list.first
  end
  crumb :exam_consolidated_exam_report do
    link I18n.t('consolidated_report'), {:controller=>"exam",:action=>"consolidated_exam_report"}
    parent :exam_exam_wise_report
  end
  crumb :exam_subject_wise_report do
    link I18n.t('subject_wise_report'), {:controller=>"exam",:action=>"subject_wise_report"}
    parent :exam_report_center
  end
  crumb :exam_generated_report2 do |subject|
    link subject.name, {:controller=>"exam",:action=>"generated_report2"}
    parent :exam_subject_wise_report
  end
  crumb :exam_grouped_exam_report do
    link I18n.t('grouped_exam_reports'), {:controller=>"exam",:action=>"grouped_exam_report"}
    parent :exam_report_center
  end
  crumb :exam_generated_report3 do |student|
    link I18n.t('subject_wise_report'), {:controller=>"exam",:action=>"generated_report3" ,:student => student.id}
    parent :student_reports,student,student.user
  end
  crumb :exam_generated_report4 do |batch|
    link batch.full_name, {:controller=>"exam",:action=>"generated_report4",:exam_report => {:batch_id =>batch.id}}
    parent :exam_grouped_exam_report
  end
  crumb :exam_generated_report4_st_view do |student|
    link I18n.t('grouped_exam_reports'), {:controller=>"exam",:action=>"generated_report4", :student => student.id}
    parent :student_reports,student,student.user
  end
  crumb :exam_reports_archived_exam_wise_report do
    link I18n.t('archived_grouped_exam_reports'), {:controller=>"exam_reports",:action=>"archived_exam_wise_report"}
    parent :exam_report_center
  end
  crumb :exam_reports_archived_batches_exam_report do |batch|
    link batch.full_name, {:controller=>"exam_reports",:action=>"archived_batches_exam_report", :exam_report=>{:batch_id=>batch.id, :course_id => batch.course.id}}
    parent :exam_reports_archived_exam_wise_report
  end
  crumb :exam_subject_rank do
    link I18n.t('student_ranking_per_subject'), {:controller=>"exam",:action=>"subject_rank"}
    parent :exam_report_center
  end
  crumb :exam_student_subject_rank do |subject|
    link subject.name, {:controller=>"exam",:action=>"student_subject_rank",:rank_report => {:batch_id =>subject.batch.id, :subject_id => subject.id}}
    parent :exam_subject_rank
  end
  crumb :exam_batch_rank do
    link I18n.t('student_ranking_per_batch'), {:controller=>"exam",:action=>"batch_rank"}
    parent :exam_report_center
  end
  crumb :exam_student_batch_rank do |batch|
    link batch.name, {:controller=>"exam",:action=>"student_batch_rank",:batch_rank => {:batch_id =>batch.id}}
    parent :exam_batch_rank
  end
  crumb :exam_course_rank do
    link I18n.t('student_ranking_per_course'), {:controller=>"exam",:action=>"course_rank"}
    parent :exam_report_center
  end
  crumb :exam_student_course_rank do |course|
    link course.full_name, {:controller=>"exam",:action=>"student_course_rank", :course_rank => {:course_id =>course.id}}
    parent :exam_course_rank
  end
  crumb :exam_attendance_rank do
    link I18n.t('student_ranking_per_attendance'), {:controller=>"exam",:action=>"attendance_rank"}
    parent :exam_report_center
  end
  crumb :exam_student_attendance_rank do |batch|
    link batch.full_name, {:controller=>"exam",:action=>"student_attendance_rank", :attendance_rank =>{:batch_id =>batch.id}}
    parent :exam_attendance_rank
  end
  crumb :exam_student_school_rank do
    link I18n.t('student_ranking_per_school'), {:controller=>"exam",:action=>"student_school_rank"}
    parent :exam_report_center
  end
  crumb :exam_ranking_level_report do
    link I18n.t('ranking_level_report'), {:controller=>"exam",:action=>"ranking_level_report"}
    parent :exam_report_center
  end
  crumb :exam_student_ranking_level_report_batch do |batch|
    link batch.name, {:controller=>"exam",:action=>"student_ranking_level_report"}
    parent :exam_ranking_level_report
  end
  crumb :exam_student_ranking_level_report_course do |course|
    link course.full_name, {:controller=>"exam",:action=>"student_ranking_level_report"}
    parent :exam_ranking_level_report
  end
  crumb :exam_transcript do
    link I18n.t('view_transcripts'), {:controller=>"exam",:action=>"transcript"}
    parent :exam_report_center
  end
  crumb :student_transcript do|batch|
    link batch.name, {:controller=>"exam",:action=>"student_transcript"}
    parent :exam_transcript
  end
  crumb :exam_combined_report do
    link I18n.t('combined_report'), {:controller=>"exam",:action=>"combined_report"}
    parent :exam_report_center
  end
  crumb :exam_student_combined_report do |batch|
    link batch.full_name, {:controller=>"exam",:action=>"student_combined_report"}
    parent :exam_combined_report
  end
  crumb :cce_reports_index do
    link I18n.t('cce_reports'), {:controller=>"cce_reports",:action=>"index"}
    parent :exam_report_center
  end
  crumb :cce_reports_create_reports do
    link I18n.t('generate_cce_report'), {:controller=>"cce_reports",:action=>"create_reports"}
    parent :cce_reports_index
  end
  crumb :cce_report_schedule_jobs do
    link "#{I18n.t('scheduled_job_for')} #{I18n.t('cce_reports')}", {:controller=>"scheduled_jobs", :job_type=>"3", :action=>"index", :job_object=>"Batch"}
    parent :cce_reports_create_reports
  end
  crumb :icse_report_schedule_jobs do
    link "#{I18n.t('scheduled_job_for')} #{I18n.t('icse_reports')}", {:controller=>"scheduled_jobs", :job_type=>"4", :action=>"index", :job_object=>"Batch"}
    parent :icse_reports_generate_reports
  end
  crumb :cce_reports_student_wise_report do
    link I18n.t('student_wise_report'), {:controller=>"cce_reports",:action=>"student_wise_report"}
    parent :cce_reports_index
  end
  crumb :cce_reports_previous_batch_exam_reports do
    link "Previous batch exam report", {:controller=>"cce_reports",:action=>"previous_batch_exam_reports"}
    parent :cce_reports_index
  end
  crumb :icse_reports_previous_batch_exam_reports do
    link "Previous batch exam report", {:controller=>"icse_reports",:action=>"previous_batch_exam_reports"}
    parent :icse_reports_index
  end
  crumb :cce_reports_consolidated_report do
    link "Consolidated Report", {:controller=>"cce_reports",:action=>"consolidated_report"}
    parent :cce_reports_index
  end
  crumb :cce_reports_detailed_fa_report do
    link "Detailed FA Report", {:controller=>"cce_reports",:action=>"detailed_fa_report"}
    parent :cce_reports_index
  end
  crumb :cce_reports_cbse_report do
    link "CBSE Report", {:controller=>"cce_reports",:action=>"cbse_report"}
    parent :cce_reports_index
  end
  crumb :cce_reports_cbse_scholastic_report do
    link "CBSE Scholastic Report", {:controller=>"cce_reports",:action=>"cbse_scholastic_report"}
    parent :cce_reports_cbse_report
  end
  crumb :cce_reports_cbse_co_scholastic_report do
    link "CBSE Co-Scholastic Report", {:controller=>"cce_reports",:action=>"cbse_co_scholastic_report"}
    parent :cce_reports_cbse_report
  end
  crumb :cce_reports_batch_student_report do
    link "Batch-Wise Student Report", {:controller=>"cce_reports",:action=>"batch_student_report"}
    parent :cce_reports_index
  end
  crumb :cce_reports_new_batch_wise_student_report do
    link "New Batch-Wise Student Report", {:controller=>"cce_reports",:action=>"new_batch_wise_student_report"}
    parent :cce_reports_batch_student_report
  end

  crumb :cce_reports_subject_wise_report do
    link I18n.t('subject_wise_report'), {:controller=>"cce_reports",:action=>"subject_wise_report"}
    parent :cce_reports_index
  end
  crumb :cce_reports_student_transcript do |student|
    link I18n.t('cce_transcript_report'), {:controller=>"cce_reports",:action=>"student_transcript", :id => student.id}
    parent :archived_student_reports,student,student.user
  end

  crumb :cce_reports_student_transcript1 do |student|
    link I18n.t('cce_transcript_report'), {:controller=>"cce_reports",:action=>"student_transcript", :id => student.id}
    parent :student_reports,student,student.user
  end

  crumb :icse_reports_student_transcript do |student|
    link "ICSE Transcript Report", {:controller=>"icse_reports",:action=>"student_transcript", :id => student.id}
    parent :student_reports,student,student.user
  end
  crumb :icse_reports_student_transcript1 do |student|
    link "ICSE Transcript Report", {:controller=>"icse_reports",:action=>"student_transcript", :id => student.id}
    parent :archived_student_reports,student,student.user
  end

  crumb :exam_settings do
    link I18n.t('settings'), {:controller => "exam", :action => "settings"}
    parent :exam_index
  end
  crumb :grading_levels_index do
    link I18n.t('grading_levels_text'), {:controller => "grading_levels", :action => "index"}
    parent :exam_settings
  end
  crumb :exam_report_settings do
    link I18n.t('report_settings'), {:controller => "exam", :action => "report_settings"}
    parent :exam_settings
  end
  crumb :ranking_levels_index do
    link I18n.t('ranking_levels_text'), {:controller => "ranking_levels", :action => "index"}
    parent :exam_settings
  end
  crumb :class_designations_index do
    link I18n.t('class_designations_text'), {:controller => "class_designations", :action => "index"}
    parent :exam_settings
  end
  crumb :exam_transcript_settings do
    link I18n.t('transcript_settings'), {:controller => "exam", :action => "transcript_settings"}
    parent :exam_settings
  end
  crumb :cce_settings_index do
    link I18n.t('cce_sttings'), {:controller => "cce_settings", :action => "index"}
    parent :exam_settings
  end
  crumb :cce_settings_basic do
    link I18n.t('basic_settings'), {:controller => "cce_settings", :action => "basic"}
    parent :cce_settings_index
  end
  crumb :cce_settings_fa_settings do
    link "Formative Assessment Settings", {:controller=>"cce_settings", :action=>"fa_settings"}
    parent :cce_settings_scholastic
  end
  crumb :cce_grade_sets_index do
    link I18n.t('grade_sets_text'), {:controller => "cce_grade_sets", :action => "index"}
    parent :cce_settings_basic
  end
  crumb :cce_grade_sets_show do |grade_set|
    link grade_set.name, {:controller => "cce_grade_sets", :action => "show", :id =>grade_set.id }
    parent :cce_grade_sets_index
  end
  crumb :cce_exam_categories_index do
    link I18n.t('cce_exam_categories_text'), {:controller => "cce_exam_categories", :action => "index"}
    parent :cce_settings_basic
  end
  crumb :cce_weightages_index do
    link I18n.t('cce_weightages'), {:controller => "cce_weightages", :action => "index"}
    parent :cce_settings_basic
  end
  crumb :cce_weightages_show do |weightage|
    link "#{weightage.weightage}(#{weightage.criteria_type})", {:controller => "cce_weightages", :action => "show", :id =>weightage.id}
    parent :cce_weightages_index
  end
  crumb :cce_weightages_assign_weightages do
    link I18n.t('assign_weightages'), {:controller => "cce_weightages", :action => "assign_weightages"}
    parent :cce_settings_basic
  end
  crumb :cce_settings_co_scholastic do
    link I18n.t('co_scholastic_settings'), {:controller => "cce_settings", :action => "co_scholastic"}
    parent :cce_settings_index
  end
  crumb :observation_groups_index do
    link I18n.t('observation_groups'), {:controller => "observation_groups", :action => "index"}
    parent :cce_settings_co_scholastic
  end
  crumb :observation_groups_show do |obs_group|
    link obs_group.name, {:controller => "observation_groups", :action => "show", :id => obs_group.id}
    parent :observation_groups_index
  end
  crumb :descriptive_indicators_index do |observation|
    link observation.name, {:controller => "descriptive_indicators", :action => "index", :observation_id=>observation.id}
    parent :observation_groups_show, observation.observation_group
  end
  crumb :descriptive_indicators_fa_index do |fa_criteria|
    link fa_criteria.fa_name, {:controller => "descriptive_indicators", :action => "index", :fa_criteria_id=>fa_criteria.id}
    parent :fa_groups_show, fa_criteria.fa_group
  end
  crumb :observation_groups_assign_courses do
    link "Assign classes", {:controller => "observation_groups", :action => "assign_courses"}
    parent :cce_settings_co_scholastic
  end
  crumb :cce_settings_scholastic do
    link I18n.t('scholastic_settings'), {:controller => "cce_settings", :action => "scholastic"}
    parent :cce_settings_index
  end
  crumb :fa_groups_index do
    link I18n.t('assessment_groups'), {:controller => "fa_groups", :action => "index"}
    parent :cce_settings_scholastic
  end
  crumb :fa_groups_show do |fa_group|
    link fa_group.name, {:controller => "fa_groups", :action => "show", :id => fa_group.id}
    parent :fa_groups_index
  end
  crumb :fa_groups_assign_fa_groups do
    link I18n.t('assign_subjects_descr'), {:controller => "fa_groups", :action => "assign_fa_groups"}
    parent :cce_settings_scholastic
  end
  crumb :fa_groups_edit_criteria_formula do |fa_group|
    link "Edit Criteria Formula", {:controller => "fa_groups", :action => "edit_criteria_formula", :id => fa_group.id}
    parent :fa_groups_show, fa_group
  end
  crumb :exam_course_wise_exams do
    link I18n.t('course_wise_exam'), {:controller => "exam", :action => "course_wise_exams"}
    parent :exam_create_exam
  end
  crumb :add_course_wise_exam do |course_exam_group|
    link I18n.t('new_exam'),{:controller => "course_exam_groups", :action => "add_exams", :batch_id =>course_exam_group.id }
    parent :course_exam_groups_show,course_exam_group
  end
  crumb :exam_students_sorting do
    link I18n.t('students_sorting'), {:controller=>"exam",:action=>"students_sorting"}
    parent :exam_settings
  end

  crumb :gradebooks_index do
    link "#{I18n.t('gradebook')}", {:controller=>"gradebooks", :action=>"index"}
  end

  crumb :gradebooks_settings do
    link "#{I18n.t('settings')}", {:controller=>"gradebooks", :action=>"settings"}
    parent :gradebooks_index
  end

  crumb :gradebooks_exam_management do
    link "#{I18n.t('manage_gradebook')}", {:controller=>"gradebooks", :action=>"exam_management"}
    parent :gradebooks_index
  end

  crumb :gradebooks_course_assessment_groups do |course,ay|
    link course.full_name, {:controller => 'gradebooks', :action=> 'course_assessment_groups', :id=>course.id, :academic_year_id=>ay.id}
    parent :gradebooks_exam_management
  end

  crumb :assessments_show do |list|
    link list.first.name, {:controller => 'assessments', :action=> 'show', :id=>list.first.id, :academic_year_id=>list.second.id, :course_id=>list.last.id}
    parent :gradebooks_course_assessment_groups, [list.last,list.second], Authorization.current_user
  end

  crumb :derived_assessments_show do |list|
    link list.first.name, {:controller => 'assessments', :action=> 'manage_derived_assessment', :id=>list.first.id, :academic_year_id=>list.second.id, :course_id=>list.last.id}
    parent :gradebooks_course_assessment_groups, [list.last,list.second], Authorization.current_user
  end

  crumb :derived_exam_show do |list|
    link "#{I18n.t('derived_exam_report')}", {:controller => 'assessments', :action=> 'show_derived_mark', :id=>list.first.id, :academic_year_id=>list.second.id, :course_id=>list.last.id}
    parent :derived_assessments_show, list
  end

  crumb :assessments_link_attributes do |list|
    link I18n.t('link_attributes'), {:controller => 'assessments', :action=> 'link_attributes', :batch_id=>list.last.id, :assessment_group_id =>list.first.id, :academic_year_id=>list.second.id}
    list.pop
    parent :assessments_show, list,list.third
  end

  crumb :assessments_activate_exams do |list|
    link I18n.t('activate_exam'), {:controller => 'assessments', :action=> 'activate_exam', :assessment_group_id =>list.first.id, :academic_year_id=>list.second.id, :course_id=>list.last.id}
    parent :assessments_show, list,list.last
  end

  crumb :assessments_enter_marks do |list|
    link I18n.t('mark_entry'), {:controller => 'assessments', :action => 'enter_marks', :assessment_group_id =>list.first.id, :batch_id=>list.last.id}
    list.pop
    parent :assessments_show, list,list.last
  end

  crumb :assessments_schedule_dates do |list|
    link I18n.t('schedule_exams'), {:controller => 'assessments', :action=> 'schedule_dates', :id=>list.first.id, :course_id => list.last.id}
    parent :assessments_show, list,list.last
  end

  crumb :assessments_generate_reports do |list|
    link I18n.t('generate_reports'), {:controller => 'assessment_reports', :action=> 'generate_exam_reports', :group_id=>list.first.id, :course_id => list.last.id,:term_id=>list[2].id}
    parent :gradebooks_course_assessment_groups, [list.last,list.second], Authorization.current_user
  end

  crumb :assessments_generate_term_reports do |list|
    link I18n.t('generate_term_reports'), {:controller => 'assessment_reports', :action=> 'generate_term_reports', :term_id=>list.first.id, :course_id => list.last.id}
    parent :gradebooks_course_assessment_groups, [list.last,list.second], Authorization.current_user
  end

  crumb :assessments_generate_planner_reports do |list|
    link I18n.t('generate_planner_report'), {:controller => 'assessment_reports', :action=> 'generate_planner_reports', :assessment_plan_id =>list.first.id, :course_id => list.last.id}
    parent :gradebooks_course_assessment_groups, [list.last,list.second], Authorization.current_user
  end

  crumb :assessment_students_planner_reports_new do |list|
    link I18n.t('student_plan_reports'), {:controller => 'assessment_reports', :action=> 'students_planner_reports', :course_id => list.last.id,:plan_id=>list.first.id}
    parent :assessments_generate_planner_reports, list, Authorization.current_user
  end

  crumb :assessment_student_report do |list|
    link I18n.t('student_exam_reports'), {:controller => 'assessment_reports', :action=> 'generate_reports', :group_id=>list.first.id, :course_id => list.last.id}
    parent :assessments_generate_reports, list, Authorization.current_user
  end

  crumb :assessment_students_term_reports_new do |list|
    link I18n.t('student_term_reports'), {:controller => 'assessment_reports', :action=> 'students_term_reports', :course_id => list.last.id,:term_id=>list.first.id}
    parent :assessments_generate_term_reports, list, Authorization.current_user
  end

  crumb :assessments_exam_timings do |list|
    link I18n.t('schedule_exams'), {:controller => 'assessments', :action=> 'exam_timings', :group_id=>list.first.id, :course_id => list.last.id}
    parent :assessments_show, list,list.last
  end

  crumb :assessments_schedule_new do |list|
    link list.last.course_name, {:controller => 'assessments', :action=> 'new'}
    parent :assessments_show, list,list.last
  end

  crumb :assessment_activities_index do
    link I18n.t('activity_profiles').titleize, {:controller=>"assessment_activities",:action=>"index"}
    parent :gradebooks_settings
  end

  crumb :exams_index do
    link I18n.t('examination'), {:controller=>"exams",:action=> "index"}
  end

  crumb :assessment_activity_profiles_show do |profile|
    link shorten_string(profile.name_was,20), {:controller=>"assessment_activities", :action=>"show", :id => profile.id}
    parent :assessment_activities_index
  end

  crumb :assessment_add_activities do |profile|
    link "#{I18n.t('add_activities')}", {:controller=>"assessment_activities", :action=>"add_activities", :id=>profile.id}
    parent :assessment_activity_profiles_show,profile
  end

  crumb :remark_banks_index do
    link I18n.t('remark_bank').titleize, {:controller=>"remark_banks",:action=>"index"}
    parent :gradebooks_settings
  end

  crumb :remark_banks_new do
    link I18n.t('create_remark_bank').titleize, {:controller=>"remark_banks",:action=>"new"}
    parent :remark_banks_index
  end

  crumb :remark_banks_show do |profile|
    link shorten_string(profile.name_was,20), {:controller=>"remark_banks", :action=>"show", :id => profile.id}
    parent :remark_banks_index
  end

  crumb :remark_banks_edit do |profile|
    link I18n.t('edit_remark_bank').titleize, {:controller=>"remark_banks",:action=>"edit"}
    parent :remark_banks_show, profile
  end

  crumb :assessment_attributes_index do
    link I18n.t('attribute_profiles').titleize, {:controller=>"assessment_attributes",:action=>"index"}
    parent :gradebooks_settings
  end

  crumb :assessment_attribute_profiles_show do |profile|
    link shorten_string(profile.name_was,20), {:controller=>"assessment_attributes", :action=>"show", :id => profile.id}
    parent :assessment_attributes_index
  end

  crumb :assessment_add_attributes do |profile|
    link "#{I18n.t('add_attributes')}", {:controller=>"assessment_attributes", :action=>"add_attributes", :id => profile.id}
    parent :assessment_attribute_profiles_show, profile
  end

  crumb :grading_profiles_index do
    link I18n.t('grading_profiles_text').titleize, {:controller=>"grading_profiles",:action=>"index"}
    parent :gradebooks_settings
  end

  crumb :grading_profiles_show do |grade|
    link shorten_string(grade.name_was,20), {:controller=>"grading_profiles",:action=>"show", :id => grade.id}
    parent :grading_profiles_index
  end

  crumb :grading_profiles_add_grades do |grade|
    link I18n.t('add_grades').titleize, {:controller=>"grading_profiles",:action=>"add_grades", :id => grade.id}
    parent :grading_profiles_show, grade
  end

  crumb :assessment_plans_index do
    link I18n.t('planner'), {:controller=>"assessment_plans", :action=>"index"}
    parent :gradebooks_index
  end

  crumb :assessment_plans_new do
    link "#{I18n.t('create_exam_plan')}", {:controller=>"assesssment_plans", :action=>"new"}
    parent :assessment_plans_index
  end

  crumb :assessment_plans_show do |plan|
    link "#{plan.name}", {:controller=>"assessment_plans", :action=>"show", :id=>plan.id}
    parent :assessment_plans_new
  end

  crumb :assessment_plans_manage_course do |plan|
    link I18n.t('courses_text').titleize, {:controller=>"assesssment_plans", :action=>"manage_courses", :id=>plan.id}
    parent :assessment_plans_show, plan
  end

  crumb :assessment_plans_add_course do |plan|
    link I18n.t('courses_text').titleize, {:controller=>"assesssment_plans", :action=>"manage_courses", :id=>plan.id}
    parent :assessment_plans_show, plan
  end

  crumb :assessment_groups_new do |list|
    link I18n.t('create_exam').titleize, {:controller=>"assessment_groups",:action=>"new", :parent_id => list.last.parent_id, :parent_type => list.last.parent_type}
    parent :assessment_plans_show, list.first
  end

  crumb :assessment_groups_planner_exam do |list|
    link I18n.t('planner_exam').titleize, {:controller=>"assessment_groups",:action=>"planner_assessment", :parent_id => list.last.parent_id, :parent_type => list.last.parent_type}
    parent :assessment_plans_show, list.first
  end

  crumb :assessment_groups_edit do |list|
    link I18n.t('edit_exam').titleize, {:controller=>"assessment_groups",:action=>"edit", :id => list.last.id}
    parent :assessment_plans_show, list.first
  end

  crumb :academic_years_index do
    link I18n.t('manage_academic_years'), {:controller=>"academic_years",:action=>"index"}
    parent :configuration_index
  end

  crumb :assessment_groups_new_course_exam do
    link I18n.t('new_exam_group').titleize, {:controller=>"assessment_groups",:action=>"new_course_exam"}
    parent :gradebooks_exam_management
  end

  crumb :assessment_groups_create_course_exam do
    link I18n.t('new_exam_group').titleize, {:controller=>"assessment_groups",:action=>"new_course_exam"}
    parent :gradebooks_exam_management
  end

  crumb :assessment_groups_edit_course_exam do
    link I18n.t('new_exam_group').titleize, {:controller=>"assessment_groups",:action=>"new_course_exam"}
    parent :gradebooks_exam_management
  end

  crumb :assessment_groups_update_course_exam do
    link I18n.t('new_exam_group').titleize, {:controller=>"assessment_groups",:action=>"new_course_exam"}
    parent :gradebooks_exam_management
  end

  crumb :assessment_report_settings do |plan|
    link I18n.t('student_report_settings'), {:controller=>'assessment_reports', :action=>'settings', :assessment_plan_id => plan.id}
    parent :assessment_plans_show, plan
  end

  crumb :assessment_students_term_reports do |list|
    link I18n.t('student_term_reports'), {:controller=>'assessment_reports', :action=>'students_term_reports', :term_id => list.last.id}
    list.pop
    parent :gradebooks_course_assessment_groups, list, Authorization.current_user
  end

  crumb :assessment_students_term_reports_profile do |list|
    link I18n.t('student_reports'), {:controller=>'assessment_reports', :action=>'students_term_reports', :term_id => list.last.id}
    parent :student_reports, list.first, Authorization.current_user
  end

  crumb :assessment_students_plan_reports_profile do |list|
    link I18n.t('student_reports'), {:controller=>'assessment_reports', :action=>'students_planner_reports', :plan_id => list.last.id}
    parent :student_reports, list.first
  end

  crumb :assessment_students_exam_reports do |list|
    link I18n.t('student_exam_reports'), {:controller=>'assessment_reports', :action=>'student_exam_reports', :group_id => list.last.id}
    list.pop
    parent :gradebooks_course_assessment_groups, list, Authorization.current_user
  end

  crumb :assessment_students_exam_reports_profile do |list|
    link I18n.t('student_reports'), {:controller=>'assessment_reports', :action=>'student_exam_reports', :group_id => list.last.id}
    parent :student_reports, list.first, Authorization.current_user
  end

  crumb :assessment_students_planner_reports do |list|
    link I18n.t('student_plan_reports'), {:controller=>'assessment_reports', :action=>'students_planner_reports', :plan_id => list.last.id}
    list.pop
    parent :gradebooks_course_assessment_groups, list
  end
  ## Course_exam_groups


  crumb :course_exam_groups_index do
    link I18n.t('exam_management'), {:controller => "course_exam_groups", :action => "index"}
    parent :exam_index
  end

  crumb :course_exam_groups_new do
    link I18n.t('create_exam_group'), {:controller => "course_exam_groups", :action => "new"}
    parent :course_exam_groups_index
  end

  crumb :create_batch_wise_exam_group do |batch|
    link I18n.t('create_exam_group_capital'), {:controller => "course_exam_groups", :action => "new"}
    parent :exam_groups_index,batch
  end

  crumb :course_exam_groups_create do
    link I18n.t('new'), {:controller => "course_exam_groups", :action => "new"}
    parent :course_exam_groups_index
  end

  crumb  :course_for_exam_groups_index do |course|
    link course.course_name , {:controller => "course_exam_groups", :action => "index",:course_id=>course.id,:batch_type=>true}
    parent :course_exam_groups_index
  end

  crumb  :course_for_batch_wise_exam_groups_index do |batch|
    link batch.course.course_name , {:controller => "course_exam_groups", :action => "index",:course_id=>batch.course.id,:batch_type=>batch.is_active}
    parent :course_exam_groups_index
  end

  crumb :course_exam_groups_show do |course_exam_group|
    link course_exam_group.name , {:controller => "course_exam_groups", :action => "show",:id=>course_exam_group.id}
    parent :course_for_exam_groups_index,course_exam_group.course
  end

  crumb :exam_groups_index do |batch|
    link "#{batch.name}", {:controller => "exam_groups", :action => "index", :batch_id =>batch.id }
    parent :course_for_batch_wise_exam_groups_index,batch,Authorization.current_user
  end

  crumb :batch_for_exam_groups_show do |exam_group|
    link exam_group.batch.full_name , {:controller => "course_exam_groups", :action => "show",:id=>exam_group.id}
    parent :course_exam_groups_index_with_params,exam_group.course_exam_group
  end

  crumb :course_wise_exam_groups_show do |exam_group|
    link exam_group.name , {:controller => "course_exam_groups", :action => "show",:id=>exam_group.id}
    parent :batch_for_exam_groups_show,exam_group
  end

  crumb :course_wise_exam_groups_show do |exam_group|
    link exam_group.name, {:controller => "exam_groups", :action => "show", :id =>exam_group.id,:batch_id =>exam_group.batch.id }
    parent :exam_groups_index, exam_group.batch, Authorization.current_user
  end
  ##

  crumb :exam_gpa_settings do
    link I18n.t('gpa_settings'), {:controller => "exam", :action => "gpa_settings"}
    parent :exam_settings
  end
  crumb :exam_previous_batch_exams do
    link "#{I18n.t('previous_batch_exam')}", {:controller => "exam", :action => "previous_batch_exams" }
    parent :course_exam_groups_index
  end
  crumb :exam_groups_new do |batch|
    link I18n.t('new_exam'), {:controller => "exam_groups", :action => "new", :batch_id =>batch.id }
    parent :exam_groups_index, batch
  end
  crumb :exam_grouping do |batch|
    link I18n.t('connect_exams'), {:controller => "exam", :action => "grouping", :id =>batch.id }
    parent :exam_groups_index, batch
  end
  crumb :exam_groups_show do |exam_group|
    link exam_group.name, {:controller => "exam_groups", :action => "show", :id =>exam_group.id,:batch_id =>exam_group.batch.id }
    parent :exam_groups_index, exam_group.batch
  end

  crumb :exam_group_show_through_course_exam_group do |exam_group|
    link exam_group.batch.name, {:controller => "exam_groups", :action => "show", :id =>exam_group.id,:batch_id =>exam_group.batch.id}
    parent :course_exam_groups_show,exam_group.course_exam_group
  end

  crumb :exams_new do |exam_group|
    link I18n.t('new_exam'), {:controller => "exams", :action => "add_new_exams", :exam_group_id =>exam_group.id }
    parent :exam_groups_show, exam_group
  end
  crumb :exams_show do |exam|
    link exam.subject.name, {:controller => "exams", :action => "show", :id => exam.id, :exam_group_id =>exam.exam_group.id }
    parent :exam_groups_show, exam.exam_group,exam.subject.batch
  end


  crumb :exams_show_through_course_exam do |exam|
    link exam.subject.name, {:controller => "exams", :action => "show", :id => exam.id, :exam_group_id =>exam.exam_group.id }
    parent :exam_group_show_through_course_exam_group,exam.exam_group,exam.subject.batch
  end


  crumb :exams_edit do |exam|
    link I18n.t('edit_text'), {:controller => "exams", :action => "edit", :id => exam.id, :exam_group_id =>exam.exam_group.id }
    parent :exams_show, exam, Authorization.current_user
  end
  crumb :assessment_scores_observation_groups do |batch|
    link I18n.t('select_a_criteria'), {:controller => "assessment_scores", :action => "observation_groups", :batch_id =>batch.id }
    parent :exam_groups_index, batch
  end
  crumb :assessment_scores_previous_observation_groups do |batch|
    link I18n.t('select_a_criteria'), {:controller => "assessment_scores", :action => "observation_groups", :batch_id =>batch.id }
    parent :exam_groups_index,batch
  end
  crumb :assessment_scores_observation_scores do |list|
    link list.last.name, {:controller => "assessment_scores", :action => "observation_scores", :batch_id =>list.first.id, :observation_group_id => list.last.id}
    parent :assessment_scores_observation_groups, list.first
  end
  crumb :assessment_scores_previous_observation_scores do |list|
    link list.last.name, {:controller => "assessment_scores", :action => "observation_scores", :batch_id =>list.first.id, :observation_group_id => list.last.id}
    parent :assessment_scores_previous_observation_groups,list.first
  end
  crumb :assessment_scores_fa_scores_with_exam do |exam|
    link 'FA Scores', {:controller => "assessment_scores", :action => "fa_scores", :exam_group_id => exam.exam_group.id, :subject_id => exam.subject.id }
    parent :exams_show, exam
  end
  crumb :assessment_scores_fa_scores_without_exam do |exam_group|
    link 'FA Scores', {:controller => "assessment_scores", :action => "fa_scores", :exam_group_id => exam_group.id }
    parent :exam_groups_show, exam_group,exam_group.batch
  end
  crumb :assessment_scores_fa_scores_with_exam_with_inactive_batch do |exam|
    link 'FA Scores', {:controller => "assessment_scores", :action => "fa_scores", :exam_group_id => exam.exam_group.id, :subject_id => exam.subject.id }
    parent :exam_edit_previous_marks, exam
  end
  crumb :assessment_scores_fa_scores_without_exam_with_inactive_batch do |exam_group|
    link 'FA Scores', {:controller => "assessment_scores", :action => "fa_scores", :exam_group_id => exam_group.id }
    parent :exam_previous_exam_marks,[exam_group.batch,exam_group],exam_group.batch
  end
  crumb :exam_generate_reports do
    link I18n.t('generate_reports'), {:controller => "exam", :action => "generate_reports"}
    parent :exam_index
  end
  crumb :exam_generate_previous_reports do
    link I18n.t('generate_previous_reports'), {:controller => "exam", :action => "generate_previous_reports"}
    parent :exam_generate_reports
  end
  crumb :current_schedule_jobs do
    link "#{I18n.t('scheduled_job_for')} #{I18n.t('current_batch')}", {:controller=>"scheduled_jobs", :job_type=>"1", :action=>"index", :job_object=>"Batch"}
    parent :exam_generate_reports
  end
  crumb :previous_schedule_jobs do
    link "#{I18n.t('scheduled_job_for')} #{I18n.t('previous_batch')}", {:controller=>"scheduled_jobs", :job_type=>"2", :action=>"index", :job_object=>"Batch"}
    parent :exam_generate_previous_reports
  end

  crumb :current_schedule_jobs do
    link "#{I18n.t('scheduled_job_for')} #{I18n.t('current_batch')}", {:controller=>"scheduled_jobs", :job_type=>"1", :action=>"index", :job_object=>"Batch"}
    parent :exam_generate_reports
  end

  ########################################
  #Reminder
  ########################################
  crumb :reminder_index do
    link I18n.t('old_inbox'), {:controller=>"reminder", :action=>"index"}
    parent :messages_index
  end
  crumb :reminder_view_reminder do |reminder|
    link "#{I18n.t('view')} #{I18n.t('message')}", {:controller=>"reminder",:id =>reminder.id ,:action=>"view_reminder"}
    parent :reminder_index
  end
  crumb :reminder_sent_reminder do
    link I18n.t('outbox'), {:controller=>"reminder", :action=>"sent_reminder"}
    parent :reminder_index
  end
  crumb :reminder_view_sent_reminder do |reminder|
    link "#{I18n.t('view')} #{I18n.t('sent_message')}", {:controller=>"reminder",:id =>reminder.id ,:action=>"view_sent_reminder"}
    parent :reminder_sent_reminder
  end
  crumb :reminder_create_reminder do
    link I18n.t('create_message'), {:controller => "reminder", :action => "create_reminder"}
    parent :reminder_index
  end
  ########################################
  #Event
  ########################################
  crumb :event_index do
    link I18n.t('event_text'), {:controller=>"event", :action=>"index"}
  end
  crumb :event_show do |event|
    link shorten_string(event.title_was,20), {:controller=>"event", :action=>"show", :id => event.id }
    parent :event_index
  end
  crumb :event_edit do |event|
    link "#{I18n.t('edit_text')} - #{shorten_string(event.title_was,20)}", {:controller=>"event", :action=>"edit", :id => event.id }
    parent :event_index
  end



  ###############################################
  #Report
  ################################################

  crumb :report_index do
    link I18n.t('reports_text'), {:controller=>"report", :action=>"index"}
  end

  crumb :report_course_batch_details do
    link I18n.t('all_courses'), {:controller=>"report", :action=>"course_batch_details"}
    parent :report_index
  end

  crumb :report_batch_details do |course|
    link course.course_name, {:controller=>"report", :action=>"batch_details",:id=>course.id}
    parent :report_course_batch_details
  end

  crumb :report_batch_students do |batch|
    link batch.name, {:controller=>"report", :action=>"batch_students",:id=>batch.id}
    parent :report_batch_details,batch.course
  end

  crumb :report_batch_details_all do
    link I18n.t('all_batches'), {:controller=>"report", :action=>"batch_details_all"}
    parent :report_index
  end

  crumb :report_students_all do
    link I18n.t('all_students'), {:controller=>"report", :action=>"students_all"}
    parent :report_index
  end

  crumb :report_employees do
    link I18n.t('all_employee'), {:controller=>"report", :action=>"employees"}
    parent :report_index
  end

  crumb :report_former_students do
    link I18n.t('former_student_details'), {:controller=>"report", :action=>"former_students"}
    parent :report_index
  end

  crumb :report_former_employees do
    link I18n.t('former_employee_details'), {:controller=>"report", :action=>"former_employees"}
    parent :report_index
  end

  crumb :report_subject_details do
    link I18n.t('subject_details'), {:controller=>"report", :action=>"subject_details"}
    parent :report_index
  end

  crumb :report_employee_subject_association do
    link I18n.t('employee_subject_association_details'), {:controller=>"report", :action=>"employee_subject_association"}
    parent :report_index
  end

  crumb :report_employee_payroll_details do
    link I18n.t('employee_payroll_details'), {:controller=>"report", :action=>"employee_payroll_details"}
    parent :report_index
  end

  crumb :report_exam_schedule_details do
    link I18n.t('exam_schedule_details'), {:controller=>"report", :action=>"exam_schedule_details"}
    parent :report_index
  end

  crumb :report_fee_collection_details do
    link I18n.t('fee_collection_details'), {:controller=>"report", :action=>"fee_collection_details"}
    parent :report_index
  end

  crumb :report_course_fee_defaulters do
    link I18n.t('course_text')+" "+I18n.t('fees_defaulters_text'), {:controller=>"report", :action=>"course_fee_defaulters"}
    parent :report_index
  end

  crumb :report_batch_fee_defaulters do |course|
    link I18n.t('batch')+" "+I18n.t('fees_defaulters_text'), {:controller=>"report", :action=>"batch_fee_defaulters",:id=>course.id}
    parent :report_course_fee_defaulters
  end

  crumb :report_batch_fee_collections do |batch|
    link I18n.t('batch')+" "+I18n.t('fee_collection'), {:controller=>"report", :action=>"batch_fee_collections",:id=>batch.id}
    parent :report_batch_fee_defaulters,batch.course
  end

  crumb :report_students_fee_defaulters do |batch|
    link I18n.t('student_wise_fee_defaulters'), {:controller=>"report", :action=>"students_fee_defaulters",:id=>batch.id}
    parent :report_batch_fee_collections,batch
  end

  crumb :report_student_wise_fee_defaulters do
    link I18n.t('student_wise_fee_defaulters'), {:controller=>"report", :action=>"student_wise_fee_defaulters"}
    parent :report_index
  end

  crumb :report_student_wise_fee_collections do |student|
    link student.full_name, {:controller=>"report", :action=>"student_wise_fee_collections",:id=>student.id}
    parent :report_student_wise_fee_defaulters
  end

  crumb :report_course_students do |course|
    link I18n.t('course_text')+" "+I18n.t('student_details'), {:controller=>"report", :action=>"course_students",:id=>course.id}
    parent :report_course_batch_details
  end


  ##########################################
  #Remarks Module
  ##########################################
  crumb :remarks_show_remarks do |student|
    link I18n.t('remarks'), {:controller=>"remarks", :action=>"custom_remark_list",:student_id=>student.id}
    parent :student_profile,student,student.user
  end

  crumb :remarks_index do
    link I18n.t('remarks'), {:controller=>"remarks", :action=>"index"}
  end

  crumb :remarks_add_employee_custom_remarks do |remark|
    link I18n.t('add_employee_custom_remarks'), {:controller=>"remarks", :action=>"add_employee_custom_remarks"}
    parent :remarks_index
  end

  crumb :remarks_employee_list_custom_remarks do
    link I18n.t('list_custom_remarks'), {:controller=>"remarks", :action=>"employee_list_custom_remarks"}
    parent :remarks_index
  end

  crumb :remarks_remarks_history do |student|
    link I18n.t('remark_history'), {:controller=>"remarks", :action=>"remarks_history",:id=>student.id}
    parent :remarks_show_remarks,student
  end

  crumb :archive_remarks_history do |student|
    link I18n.t('remark_history'), {:controller=>"remarks", :action=>"remarks_history",:id=>student.id}
    parent :archived_student_profile,student
  end

  crumb :report_fees_head_wise_report do
    link I18n.t('fees_head_wise_report'), {:controller=>"report", :action=>"fees_head_wise_report"}
    parent :report_index
  end

  crumb :report_batch_fees_headwise_report do
    link "#{I18n.t('batch')} #{I18n.t('wise')} #{I18n.t('report')}", {:controller=>"report", :action=>"batch_fees_headwise_report"}
    parent :report_fees_head_wise_report
  end

  crumb :report_fee_collection_report do
    link "#{I18n.t('collection_report')} ", {:controller=>"report", :action=>"collection_report"}
    parent :report_fees_head_wise_report
  end

  crumb :report_siblings_report do
    link "#{I18n.t('siblings')} #{I18n.t('report')}", {:controller=>"report", :action=>"siblings_report"}
    parent :report_index
  end

  crumb :report_fee_collection_head_wise_report do
    link "#{I18n.t('fee_collection')} #{I18n.t('wise')} #{I18n.t('report')}", {:controller=>"report", :action=>"fee_collection_head_wise_report"}
    parent :report_fees_head_wise_report
  end

  crumb :report_search_student do
    link "#{I18n.t('students')} #{I18n.t('wise')} #{I18n.t('report')}", {:controller=>"report", :action=>"search_student"}
    parent :report_fees_head_wise_report
  end

  crumb :report_student_fees_headwise_report do |student|
    link student.full_name, {:controller=>"report", :action=>"student_fees_headwise_report",:id=>student.id}
    parent :report_search_student
  end

  #  crumb :project do |project|
  #    link lambda { |project| "#{project.name} (#{project.id.to_s})" }, project_path(project)
  #    parent :projects
  #  end
  #
  #  crumb :project_issues do |project|
  #    link "Issues", project_issues_path(project)
  #    parent :project, project
  #  end
  #
  #  crumb :issue do |issue|
  #    link issue.name, issue_path(issue)
  #    parent :project_issues, issue.project
  #  end
  #
  crumb :icse_settings_index do
    link "ICSE Settings", {:controller=>"icse_settings", :action=>"index"}
    parent :exam_settings
  end
  crumb :icse_settings_ia_settings do
    link "Internal Assessment Settings", {:controller=>"icse_settings", :action=>"ia_settings"}
    parent :icse_settings_index
  end

  crumb :icse_settings_icse_exam_categories do
    link "ICSE Exam Categories", {:controller=>"icse_settings", :action=>"icse_exam_categories"}
    parent :icse_settings_index
  end

  crumb :icse_settings_icse_weightages do
    link "ICSE Weightages", {:controller=>"icse_settings", :action=>"icse_weightages"}
    parent :icse_settings_index
  end

  crumb :icse_settings_assign_icse_weightages do
    link "Assign Weightages",{:controller=>"icse_settings", :action=>"assign_icse_weightages"}
    parent :icse_settings_index
  end
  crumb :icse_settings_internal_assessment_groups do
    link "IA Groups" ,{:controller=>"icse_settings", :action=>"internal_assessment_groups"}
    parent :icse_settings_index
  end
  crumb :icse_settings_new_ia_group do
    link "New IA Group" ,{:controller=>"icse_settings", :action=>"new_ia_group"}
    parent :icse_settings_internal_assessment_groups
  end

  crumb :icse_settings_create_ia_group do
    link "New IA Group" ,{:controller=>"icse_settings", :action=>"new_ia_group"}
    parent :icse_settings_internal_assessment_groups
  end
  crumb :icse_settings_edit_ia_group do |ia_group|
    link "Edit IA Group" ,{:controller=>"icse_settings", :action=>"new_ia_group",:id=>ia_group.id}
    parent :icse_settings_internal_assessment_groups
  end
  crumb :icse_settings_assign_ia_groups do
    link "Assign IA Groups" ,{:controller=>"icse_settings", :action=>"assign_ia_groups"}
    parent :icse_settings_index
  end
  crumb :ia_scores do |exam|
    link "IA Scores" , {:controller=>:ia_scores,:action=>:ia_scores,:exam_id=>exam.id}
    parent :exams_show,exam
  end
  crumb :ia_scores_previous do |exam|
    link "IA Scores" , {:controller=>:ia_scores,:action=>:ia_scores,:exam_id=>exam.id}
    parent :exam_edit_previous_marks,exam,exam.subject
  end
  crumb :icse_reports_index do
    link "ICSE Reports", {:controller=>:icse_reports,:action=>:index}
    parent :exam_report_center
  end
  crumb :icse_reports_generate_reports do
    link "Generate ICSE report",{:controller=>:icse_reports,:action=>:generate_reports}
    parent :icse_reports_index
  end
  crumb :icse_reports_student_wise_report do
    link "Student-wise report",{:controller=>:icse_reports,:action=>:student_wise_report}
    parent :icse_reports_index
  end
  crumb :icse_reports_subject_wise_report do
    link "Subject-wise report",{:controller=>:icse_reports,:action=>:subject_wise_report}
    parent :icse_reports_index
  end
  crumb :icse_reports_consolidated_report do
    link "Consolidated report",{:controller=>:icse_reports,:action=>:consolidated_report}
    parent :icse_reports_index
  end


  #leave management


  crumb :employee_attendance_settings do
    link "#{I18n.t('leave_process_settings')}", {:controller => "employee_attendance", :action => "settings"}
    parent :leave_years_index
  end

  crumb :employee_attendance_reset_logs do
    link "#{I18n.t('leave_reset_records')}", {:controller => "employee_attendance", :action => "reset_logs"}
    parent :employee_employee_attendance
  end

  crumb :employee_attendance_reset_all_employees do
    link "#{I18n.t('reset_leaves_of_all_employees')}", {:controller => "employee_attendance", :action => "reset_all_employees"}
    parent :employee_attendance_reset_leaves
  end

  crumb :employee_attendance_reset_by_leave_groups do
    link "#{I18n.t('reset_by_leave_group')}", {:controller => "employee_attendance", :action => "reset_by_leave_groups"}
    parent :employee_attendance_reset_leaves
  end

  crumb :employee_attendance_reset_by_leave_groups_modal do
    link "#{I18n.t('reset_by_leave_group')}", {:controller => "employee_attendance", :action => "reset_by_leave_groups"}
    parent :employee_attendance_reset_leaves
  end

  crumb :employee_attendance_reset_employee_leaves do
    link "#{I18n.t('reset_leaves_of_all_employees')}", {:controller => "employee_attendance", :action => "reset_all_employees"}
    parent :employee_attendance_reset_logs
  end

  crumb :employee_attendance_reset_leaves do
    link "#{I18n.t('reset_leaves')}", {:controller => "employee_attendance", :action => "reset_leaves"}
    parent :employee_attendance_reset_logs
  end

  crumb :employee_attendance_employee_reset_logs do
    link "#{I18n.t('leave_reset_status')}", {:controller => "employee_attendance", :action => "employee_reset_logs"}
    parent :employee_attendance_reset_logs
  end

  crumb :employee_attendance_reset_settings do
    link "#{I18n.t('leave_reset_settings')}", {:controller => "employee_attendance", :action => "reset_settings"}
    parent :employee_attendance_reset_logs
  end
  
  crumb :employee_attendance_leave_applications do
    link "#{I18n.t('leave_applications').titleize}", {:controller => "employee_attendance", :action => "leave_applications"}
    parent :employee_employee_attendance
  end

  crumb :transfer_certificate do
    link I18n.t('transfer_certificate'), {:controller=>"tc_templates",:action=>"index"}
  end

  crumb :tc_template_settings do
    link I18n.t('tc_template_settings'), {:controller=>"tc_templates",:action=>"settings"}
    parent :transfer_certificate
  end

  crumb :tc_header_settings do
    link I18n.t('tc_header_settings'), {:controller=>"tc_template_headers",:action=>"edit"}
    parent :tc_template_settings
  end

  crumb :tc_footer_settings do
    link I18n.t('tc_signature_and_clauses_settings'), {:controller=>"tc_template_footers",:action=>"edit"}
    parent :tc_template_settings
  end

  crumb :tc_student_details_settings do
    link I18n.t('transfer_certificate_student_details'), {:controller=>"tc_template_student_details",:action=>"index"}
    parent :tc_template_settings
  end

  crumb :tc_template_generated_certificate do
    link I18n.t('tc_template_generated_certificate'), {:controller=>"tc_template_generate_certificates",:action=>"generated_certificates"}
    parent :transfer_certificate
  end

  crumb :tc_template_generate_certificate do
    link I18n.t('tc_template_generate_certificate'), {:controller=>"tc_template_generate_certificates",:action=>"index"}
    parent :transfer_certificate
  end

  crumb :tc_template_generate_report do |student|
    link student.full_name, {:controller=>"tc_template_generate_certificates",:action=>"edit",:id=>student.id}
    parent :tc_template_generate_certificate
  end

  crumb :tc_template_generate_report_preview do |student|
    link I18n.t('preview'), {:controller=>"tc_template_generate_certificates",:action=>"preview"}
    parent :tc_template_generate_report, student
  end

  crumb :tc_template_record_show do |student|
    link "#{student.full_name}", {:controller=>"tc_template_generate_certificates",:action=>"show", :id=>student.id}
    parent :tc_template_generated_certificate
  end

  crumb :feature_access_settings do
    link I18n.t('feature_access_settings'), {:controller=>":feature_access_settings",:action=>"index"}
    parent :configuration_index
  end

  crumb :messages_index do
    link I18n.t('messages'), {:controller=>"messages",:action=>"index"}
  end

  crumb :create_broadcast_message do
    link  "#{I18n.t('create_text')} #{I18n.t('broadcast_message')}", {:controller=>"messages",:action=>"create_broadcast"}
    parent :messages_index
  end

  crumb :message_settings do
    link  "#{I18n.t('settings')}", {:controller=>"messages",:action=>"message_settings"}
    parent :messages_index
  end

  crumb :notifications_index do
    link "#{I18n.t('all')} #{I18n.t('notifications')}", {:controller=>"notifications",:action=>"index"}
  end

  #tax & tax report pages
  crumb :finance_tax_index do
    link "#{I18n.t('finance_tax')}", {:controller => "finance", :action => "tax_index"}
    parent :finance_index
  end

  crumb :finance_tax_settings do
    link "#{I18n.t('tax_settings')}", {:controller => "finance", :action => "tax_settings"}
    parent :finance_tax_index
  end

  crumb :tax_slabs_index do
    link "#{I18n.t('tax_slabs_text')}", { :controller => "tax_slabs", :action => "index"}
    parent :finance_tax_index
  end

  crumb :finance_extensions_tax_report do
    link I18n.t('tax_report'), { :controller => "finance_extensions", :action => "tax_report"}
    parent :finance_reports_index
  end

  crumb :finance_extensions_update_tax_report do |date_range|
    link I18n.t('tax_report'), { :controller => "finance_extensions", :action=>"update_taxreport",
      :start_date => date_range.first.to_date, :end_date => date_range.last.to_date}
    parent :finance_extensions_tax_report
  end

  #begin GradebookReports -------->
  crumb :gradebook_reports_index do
    link I18n.t('gradebook_reports'), { :controller => "gradebook_reports", :action => "index"}
    parent :gradebooks_index
  end

  crumb :gradebook_reports_student_reports do
    link I18n.t('student_reports'), { :controller => "gradebook_reports", :action => "student_reports"}
    parent :gradebook_reports_index
  end

  crumb :assessment_import_planner do
    link I18n.t('import_planner'), { :controller => "assessment_plans", :action => "import_planner"}
    parent :assessment_plans_index
  end

  crumb :assessment_planner_import_logs do
    link I18n.t('import_planner_logs'), { :controller => "assessment_plans", :action => "import_logs"}
    parent :assessment_import_planner
  end

  crumb :gradebook_reports_subject_reports do
    link I18n.t('subject_reports'), { :controller => "gradebook_reports", :action => "subject_reports"}
    parent :gradebook_reports_index
  end

  crumb :gradebook_reports_consolidated_exam_report do
    link I18n.t('consolidated_reports'), { :controller => "gradebook_reports", :action => "consolidated_exam_report"}
    parent :gradebook_reports_index
  end

  crumb :assessment_imports do |list|
    link I18n.t('assessment_mark_import'), { :controller => "assessment_imports", :action => "imports", :batch_id => list.first.id, :assessment_group_id => list.last.id}
    parent :assessments_show, [list.last, list.last.academic_year, list.first.course],list.first.course
  end

  crumb :gradebook_attendance_attendance_entry do |list|
    link I18n.t('gradebook_attendance'), { :controller => ":gradebook_attendance", :action => "attendance_entry", :batch_id => list.first.id, :assessment_group_id => list.last.id}
    parent :gradebooks_course_assessment_groups, list,Authorization.current_user
  end

  crumb :gradebook_attendance_period do |list|
    link I18n.t('attendance_period'), { :controller => ":gradebook_attendance", :action => "attendance_period", :batch_id => list.first.id, :assessment_group_id => list.last.id}
    parent :gradebooks_course_assessment_groups, list,Authorization.current_user
  end

  crumb :gradebook_remarks_manage do |list|
    link I18n.t('manage_remarks'), { :controller => ":gradebook_remarks", :action => "manage", :id => list.first.id, :academic_year_id => list.last.id}
    parent :gradebooks_course_assessment_groups, list, Authorization.current_user
  end

  #GradebookReports end ---------->

  crumb :certificate_templates_index do
    link I18n.t('certificates'), { :controller => "certificate_templates", :action => "index"}
  end


  crumb :certificate_templates_certificate_templates do
    link I18n.t('certificate_templates'), { :controller => "certificate_templates", :action => "certificate_templates"}
    parent :certificate_templates_index
  end

  crumb :certificate_templates_new_certificate_template do
    link I18n.t('new_certificate_template'), { :controller => "certificate_templates", :action => "new_template"}
    parent :certificate_templates_certificate_templates
  end

  crumb :employee_attendance_leave_balance_report do
    link I18n.t('leave_balance_report'), {:controller=>"employee_attendance",:action=>"leave_balance_report"}
    parent :employee_employee_attendance
  end


  #----Subjects Center ---------->

  crumb :subjects_center_index do
    link I18n.t('subjects_center_text'), { :controller => "subjects_center", :action => "index"}
  end

  crumb :subjects_center_subject_groups do
    link I18n.t('subject_group'), { :controller => "subjects_center", :action => "subject_groups"}
    parent :subjects_center_index
  end

  crumb :subjects_center_course_subjects do
    link I18n.t('course_subjects'), { :controller => "subjects_center", :action => "course_subjects"}
    parent :subjects_center_index
  end

  # finance settings
  crumb :finance_settings_index do
    link I18n.t('finance_settings_text'), {:controller => "finance_settings", :action => "index"}
    parent :finance_index
  end

  # crumb :finance_settings_fee_settings do
  #   link I18n.t('fee_settings'), {:controller => "finance_settings", :action => "fee_settings"}
  #   parent :finance_settings_index
  # end

  crumb :finance_settings_fee_general_settings do
    link I18n.t('fee_general_settings'), {:controller => "finance_settings", :action => "fee_general_settings"}
    # parent :finance_settings_fee_settings
    parent :finance_settings_index
  end

  crumb :finance_settings_receipt_print_settings do
    link I18n.t('fees_receipt_settings'), {:controller => "finance_settings", :action => "receipt_print_settings"}
    # parent :finance_settings_fee_settings
    parent :finance_settings_index
  end

  crumb :finance_settings_receipt_pdf_settings do
    link I18n.t('pdf_receipt_settings'), {:controller => "finance_settings", :action => "receipt_pdf_settings"}
    # parent :finance_settings_fee_settings
    parent :finance_settings_index
  end

  # fee accounts
  crumb :fee_accounts_index do
    link I18n.t('fee_accounts_text'), {:controller => "fee_accounts", :action => "index"}
    # parent :finance_settings_fee_settings
    parent :finance_settings_index
  end

  crumb :fee_accounts_manage do
    link I18n.t('fee_accounts.manage_fee_account'), {:controller => "fee_accounts", :action => "manage"}
    # parent :finance_settings_fee_settings
    parent :fee_accounts_index
  end
  # receipt sets
  crumb :receipt_sets_index do
    link I18n.t('receipt_sets_text'), {:controller => "receipt_sets", :action => "index"}
    # parent :finance_settings_fee_settings
    parent :finance_settings_index
  end
  # receipt templates
  crumb :receipt_templates_index do
    link I18n.t('receipt_templates_text'), {:controller => "receipt_templates", :action => "index"}
    # parent :finance_settings_fee_settings
    parent :finance_settings_index
  end
  # new receipt template
  crumb :receipt_templates_new do
    link I18n.t('receipt_templates.create_receipt_template'), {:controller => "receipt_templates", :action => "new"}
    parent :receipt_templates_index
  end
  crumb :receipt_templates_create do
    link I18n.t('receipt_templates.create_receipt_template'), {:controller => "receipt_templates", :action => "create"}
    parent :receipt_templates_index
  end
  # edit receipt template
  crumb :receipt_templates_edit do |receipt_template|
    link I18n.t('receipt_templates.edit_receipt_template'), {:controller => "receipt_templates", :action => "edit", :id => receipt_template.id}
    parent :receipt_templates_index
  end
  #  crumb :finance_fees_receipt_settings do
  #    link I18n.t('fees_receipt_settings'), {:controller=>"finance",:action=>"fees_receipt_settings"}
  #    parent :finance_receipt_settings
  #  end
  #
  #  crumb :finance_pdf_receipt_settings do
  #    link I18n.t('pdf_receipt_settings'), {:controller=>"finance",:action=>"pdf_receipt_settings"}
  #    parent :finance_receipt_settings
  #  end
  crumb :subject_skill_sets_index do
    link I18n.t('subject_skill_set'), { :controller => "subject_skill_sets", :action => "index"}
    parent :subjects_center_index
  end

  crumb :subject_skill_sets_show do |set|
    link set.name, { :controller => "subject_skill_sets", :action => "show", :id => set.id}
    parent :subject_skill_sets_index
  end

  crumb :add_subject_skills do |set|
    link I18n.t('manage_skill'), { :controller => "subject_skill_sets", :action => "add_skills", :id => set.id}
    parent :subject_skill_sets_show, set
  end

  crumb :add_subject_sub_skills do |skill|
    link skill.name, { :controller => "subject_skill_sets", :action => "add_sub_skills"}
    parent :subject_skill_sets_show, skill.subject_skill_set
  end

  crumb :certificate_templates_edit_certificate_template do
    link I18n.t('edit_certificate_template'), { :controller => "certificate_templates", :action => "edit_template"}
    parent :certificate_templates_certificate_templates
  end

  crumb :certificate_templates_generate_certificate do
    link I18n.t('generate_individual_certificates'), { :controller => "certificate_templates", :action => "generate_certificate"}
    parent :certificate_templates_index
  end

  crumb :certificate_templates_generated_certificates do
    link I18n.t('generated_certificates'), { :controller => "certificate_templates", :action => "generated_certificates"}
    parent :certificate_templates_index
  end

  crumb :certificate_templates_list_generated_certificates do |certificate_template|
    link "#{certificate_template.name}", { :controller => "certificate_templates", :action => "list_generated_certificates",:certificate_template_id=>certificate_template.id}
    parent :certificate_templates_generated_certificates
  end

  crumb :certificate_templates_list_generated_certificates do |certificate_template|
    link "#{certificate_template.name}", { :controller => "certificate_templates", :action => "list_generated_certificates",:certificate_template_id=>certificate_template.id}
    parent :certificate_templates_generated_certificates
  end

  crumb :certificate_templates_bulk_export do
    link I18n.t('bulk_export'), { :controller => "certificate_templates", :action => "bulk_export"}
    parent :certificate_templates_index
  end


  crumb :id_card_templates_index do
    link I18n.t('id_cards'), { :controller => "id_card_templates", :action => "index"}
  end

  crumb :id_card_templates_id_card_templates do
    link I18n.t('id_card_templates'), { :controller => "id_card_templates", :action => "id_card_templates"}
    parent :id_card_templates_index
  end

  crumb :id_card_templates_new_id_card_template do
    link I18n.t('new_id_card_template'), { :controller => "id_card_templates", :action => "new_id_card_template"}
    parent :id_card_templates_id_card_templates
  end

  crumb :id_card_templates_edit_id_card_template do
    link I18n.t('edit_id_card_template'), { :controller => "id_card_templates", :action => "edit_id_card_template"}
    parent :id_card_templates_id_card_templates
  end

  crumb :id_card_templates_generated_id_cards do
    link I18n.t('generated_id_cards'), { :controller => "id_card_templates", :action => "generated_id_cards"}
    parent :id_card_templates_index
  end

  crumb :id_card_templates_generate_id_card do
    link I18n.t('generate_individual_id_card'), { :controller => "id_card_templates", :action => "generate_id_card"}
    parent :id_card_templates_index
  end

  crumb :id_card_templates_bulk_export do
    link I18n.t('bulk_export'), { :controller => "id_card_templates", :action => "bulk_export"}
    parent :id_card_templates_index
  end

  crumb :id_card_templates_list_generated_id_cards do |id_card_template|
    link "#{id_card_template.name}", { :controller => "id_card_templates", :action => "list_generated_id_cards", :id_card_template_id=>id_card_template.id}
    parent :id_card_templates_generated_id_cards
  end

  crumb :subjects_center_link_batches do
    link I18n.t('link_batches'), { :controller => "subjects_center", :action => "link_batches"}
    parent :subjects_center_index
  end

  crumb :subjects_center_connect_subjects do
    link I18n.t('connect_subjects'), { :controller => "subjects_center", :action => "connect_subjects"}
    parent :subjects_center_link_batches
  end

  crumb :subjects_center_import_subjects do
    link I18n.t('import_subjects'), { :controller => "subjects_center", :action => "import_subjects"}
    parent :subjects_center_index
  end

  crumb :subjects_center_import_logs do
    link I18n.t('subject_import_logs'), { :controller => "subjects_center", :action => "import_logs"}
    parent :subjects_center_course_subjects
  end  
  # automatic leave credit------------------
  
  crumb :leave_years_index do
    link I18n.t('manage_leave_years'), {:controller=>"leave_years",:action=>"index"}
    parent :leave_years_leave_process_settings
  end
 
  crumb :leave_years_autocredit_setting do
    link I18n.t('manage_autocredits'), {:controller=>"leave_years",:action=>"autocredit_setting"}
    parent :leave_years_leave_process_settings
  end
  crumb :employee_attendance_credit_logs do
    link "#{I18n.t('leave_credit_records')}", {:controller => "employee_attendance", :action => "credit_logs"}
    parent :employee_employee_attendance
  end
  crumb :employee_attendance_credit_leaves do
    link "#{I18n.t('credit_leaves')}", {:controller => "employee_attendance", :action => "credit_leaves"}
    parent :employee_attendance_credit_logs
  end
  crumb :employee_attendance_credit_by_leave_groups do
    link "#{I18n.t('credit_by_leave_group')}", {:controller => "employee_attendance", :action => "credit_by_leave_groups"}
    parent :employee_attendance_credit_leaves
  end
  
  crumb :employee_attendance_credit_all_employees do
    link "#{I18n.t('credit_leaves_of_all_employees')}", {:controller => "employee_attendance", :action => "credit_all_employees"}
    parent :employee_attendance_credit_leaves
  end
 
  crumb :employee_attendance_employee_credit_logs do
    link "#{I18n.t('leave_credit_status')}", {:controller => "employee_attendance", :action => "employee_credit_logs"}
    parent :employee_attendance_credit_logs
  end
  
  crumb :leave_years_leave_process do
    link I18n.t('manage_leave_process'), {:controller=>"leave_years",:action=>"index"}
    parent :leave_years_index
  end
  
  crumb :leave_years_leave_records do 
    link "#{I18n.t('leave_reset_records')}", {:controller => "leave_years", :action => "leave_records" }
    parent :leave_years_index
  end
  
  crumb :leave_years_end_year_process_detail do 
    link "#{I18n.t('leave_reset_records')}", {:controller => "leave_years", :action => "end_year_process_detail" }
    parent :leave_years_leave_records
  end
  
  crumb :leave_years_reset_setting do
    link I18n.t('manage_reset_setting'), {:controller=>"leave_years",:action=>"reset_setting"}
    parent :employee_settings
  end
  
  crumb :leave_years_credit_date_setting do
    link I18n.t('manage_credit_date_setting'), {:controller=>"leave_years",:action=>"credit_date_setting"}
    parent :leave_years_leave_process_settings
  end
  
  crumb :leave_years_leave_process_settings do
    link I18n.t('manage_leave_process_settings'), {:controller=>"leave_years",:action=>"leave_process_settings"}
    parent :employee_settings
  end
 

  crumb :message_templates_message_templates do
    link I18n.t('message_templates'), { :controller => "message_templates", :action => "message_templates"}
    parent :sms_index
  end
  
  crumb :message_templates_new_message_template do
    link I18n.t('message_templates'), { :controller => "message_templates", :action => "new_message_template"}
    parent :message_templates_message_templates
  end

  crumb :message_templates_edit_message_template do
    link I18n.t('message_templates'), { :controller => "message_templates", :action => "edit_message_template"}
    parent :message_templates_message_templates
  end

  ########################################
  #User Group
  ########################################
  crumb :user_groups_index do
    link I18n.t('user_groups'), {:controller=>"user_groups", :action=>"index"}
  end
  crumb :user_groups_create do
    link I18n.t('user_group_new_text'), {:controller=>"user_groups", :action=>"create_user_group"}
    parent :user_groups_index
  end
  crumb :user_groups_show do |group|
    link "#{group.name}", {:controller=>"user_groups", :action=>"show_user_group", :id => group.id }
    parent :user_groups_index
  end
  crumb :user_groups_edit do |group|
    link I18n.t('user_group_edit_text'), {:controller=>"user_groups", :action=>"edit_user_group", :id => group.id}
    parent :user_groups_show,group
  end
  
end

