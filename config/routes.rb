ActionController::Routing::Routes.draw do |map|

  map.resources :student_roll_number, :member => {:view_batches => [:get,:post], :create_roll_numbers => [:get,:post],  :update_roll_numbers => [:get,:post],  :edit_roll_numbers => [:get,:post]}
  map.resources :grading_levels
  map.resources :tax_slabs
  map.resources :hook, :collection => { :sms => :get}
  map.resources :multi_fee_discounts
  map.resources :ranking_levels, :collection => {:create_ranking_level=>[:get,:post], :edit_ranking_level=>[:get,:post], :update_ranking_level=>[:get,:post], :delete_ranking_level=>[:get,:post], :ranking_level_cancel=>[:get,:post], :change_priority=>[:get,:post]}
  map.resources :class_designations
  map.resources :class_timings, :except => [:index, :show]
  map.resources :class_timing_sets,
    :member => {:new_class_timings => [:post],:create_class_timings => [:post],:edit_class_timings => [:post],:update_class_timings => [:post],:delete_class_timings => [:post,:delete]},
    :collection => {:change_default_class_timing_set=>[:get,:post],:new_batch_class_timing_set => [:get],:list_batches => [:post],:add_batch => [:post]}
  map.resources :subjects, :collection => {:enable_elective_group_delete => :get, :edit_component => :get, :delete_component => :delete, :update_component => :put}
  map.resources :attendances, :collection=>{:daily_register=>:get,:subject_wise_register=>:get,:quick_attendance=>:get,:notification_status => [:get,:post],:list_subjects => [:get,:post],:send_sms_for_absentees => [:get,:post],:attendance_register_pdf => [:get,:post], :attendance_register_csv => [:get,:post],:save_attendance => [:post, :get], :lock_attendance => [:post, :get], :unlock_attendance => [:post, :get]}
  map.resources :employee_attendances
  map.resources :attendance_labels, :member => {:make_configuration => [:post, :get] ,:remove_configuration => [:post, :get], :delete_label => [:get]}
  map.resources :attendance_reports,:collection=>{:report_pdf=>[:get],:consolidated_report=>[:get],:filter_report_pdf=>[:get],:day_wise_report => [:get,:post],:day_wise_report_filter_by_course => [:get,:post],:daily_report_batch_wise => [:get,:post]}
  map.resources :cce_exam_categories
  map.resources :assessment_scores,:collection=>{:exam_fa_groups=>[:get],:observation_groups=>[:get],:get_fa_groups=>[:get],:scores_form=>[:get,:post]}
  map.resources :cce_settings,:collection=>{:basic=>[:get],:scholastic=>[:get],:co_scholastic=>[:get],:fa_settings=>[:get,:put],:fa_average_example=>:get,:fa_total_example=>:get}
  map.resources :cce_report_settings,:collection=>{:co_scholastic_remarks_settings=>[:get,:post],:cbse_co_scholastic_settings=>[:get,:post],:upscale_scores=>[:get,:post],:upscale_settings=>[:get,:post],:normal_report_settings=>[:get,:post],:settings=>[:get,:post],:unlink=>[:get,:post]},:only=>[:settings,:upscale_settings,:upscale_score,:normal_report_settings]
  map.resources :scheduled_jobs,:except => [:show]
  map.resources :fa_groups,:collection=>{:formula_examples=>:get,:assign_fa_groups=>[:get,:post],:new_fa_criteria=>[:get,:post],:create_fa_criteria=>[:get,:post],:edit_fa_criteria=>[:get,:post],:update_fa_criteria=>[:get,:post],:destroy_fa_criteria=>[:post],:reorder=>[:get,:post]},
    :member=>{:edit_criteria_formula=>[:get,:post,:put]}
  map.resources :payroll_categories, :collection => {:index => [:get, :post], :validate_formula => :get}, :member => {:destroy_category => :get}
  map.resources :payroll_groups,  :collection => {:working_day_settings => :get, :update_working_day_settings => [:get, :post]}, :member => {:lop_settings => :get, :save_lop_settings => [:put, :get], :categories_formula => [:get, :post]}
  map.resources :leave_groups, :member => {:add_leave_types => [:get, :put], :add_employees => [:get, :post], :manage_employees => [:get, :post], :remove_leave_type => :get, :save_employees => [:put], :advanced_search => :get, :remove_employee => [:post], :leave_group_details => :post, :delete_group => :get}
  map.resources :employee_payslips, :collection => {:view_sample_payslip => [:get] ,:payslip_settings => [:get], :search_employees => [:get],:save_employee_payslips => [:get,:post],:fetch_employee_payslips => [:get], :view_employee_past_payslips => [:get,:post],:generate_employee_payslip => [:get,:post],:view_past_payslips => [:get, :post],:payslip_generation_list => [:get,:post],:generate_payslips => [:get,:post],:payrollgroup_based_payslips => [:get, :post], :payslip_for_payroll_group => [:get,:post], :payslip_for_employees => [:get,:post], :create_employee_wise_payslip => [:get, :post, :put], :calculate_lop_values => [:get, :post], :revert_employee_payslip => [:get], :view_employee_pending_payslips => :get, :view_all_rejected_payslips => [:get, :post], :approve_payslips => [:get, :post], :approve_payslips_range => [:get, :post]}
  map.resources :payroll, :member => {:assign_employees => [:get, :post], :assigned_employees => [:get, :post], :create_employee_payroll => [:get,:post],:add_employee_payroll => [:get, :post, :put], :calculate_employee_payroll_components => [:get, :post]}, :collection => {:settings => [:get, :post, :put]}
  map.resources :hr_reports, :only => [:index, :destroy], :collection => {:report => [:get], :fetch_reports => [:get, :post], :fetch_dependent_values => [:get, :post], :fetch_filters => [:get, :post], :report_csv => :get, :template_csv => :get, :save_template => [:get, :post]}, :member => {:template => [:get, :post], :fetch_template_filters => [:get, :post], :fetch_template_reports => [:get, :post]}
  map.resources :fa_criterias do |fa|
    fa.resources :descriptive_indicators
  end
  map.resources :observations do |obs|
    obs.resources :descriptive_indicators
  end
  map.resources :observation_groups,:member=>{:new_observation=>[:get,:post],:create_observation=>[:get,:post],:edit_observation=>[:get,:post],:update_observation=>[:get,:post],:destroy_observation=>[:post],:reorder=>[:get,:post]},:collection=>{:assign_courses=>[:get,:post],:set_observation_group=>[:get,:post]}
  map.resources :cce_weightages,:member=>{:assign_courses=>[:get,:post]},:collection=>{:assign_weightages=>[:get,:post]}
  map.resources :cce_grade_sets, :member=>{:new_grade=>[:get,:post],:edit_grade=>[:get,:post],:update_grade=>[:get,:post],:destroy_grade=>[:post]}

  map.feed 'courses/manage_course', :controller => 'courses' ,:action=>'manage_course'
  map.feed 'courses/manage_batches', :controller => 'courses' ,:action=>'manage_batches'
  map.resources :courses, :collection => {:grouped_batches=>[:get,:post],:create_batch_group=>[:get,:post],:edit_batch_group=>[:get,:post],:update_batch_group=>[:get,:post],:delete_batch_group=>[:get,:post],:assign_subject_amount => [:get,:post],:edit_subject_amount => [:get,:post],:destroy_subject_amount => [:get,:post]} do |course|
    course.resources :batches
  end

  map.resources :batches,:only => [], :member=>{:batch_summary=>[:get,:post]},:collection=>{:batches_ajax=>[:get]} do |batch|
    batch.resources :exam_groups
    batch.resources :elective_groups, :as => :electives, :member => {:new_elective_subject => [:get, :post], :create_elective_subject => [:get,:post], :edit_elective_subject => [:get, :post, :put], :update_elective_subject => [:get, :post, :put]}
  end

  map.resources :exam_groups do |exam_group|
    exam_group.resources :exams, :member => { :save_scores => [:post]},:collection=>{:add_new_exams=>[:get,:post,:put]}
  end

  map.resources :buildings do |building|
    building.resources :classrooms, :except => [:index]
  end
  map.resources :classrooms
  map.resources :classroom_allocations, :collection=>{:weekly_allocation=>:get, :render_classrooms => :get, :display_rooms => :get, :date_specific_allocation => :get, :update_allocation_entries => :get, :override_allocations => :get,:delete_allocation => :get, :find_allocations => :get}
  map.resources :certificate_templates, :collection=>[:certificate_templates, :new_certificate_template, :edit_certificate_template, :update_certificate_template, :delete_certificate_template , :save_certificate_template, :generate_certificate, :certificate_keys, :certificate_template_for_generation, :download_image, :generated_certificates, :save_generated_certificate, :generate_certificate_pdf, :list_generated_certificates, :bulk_export, :batch_students,:generate_bulk_export_pdf_student, :generate_bulk_export_pdf_employee, :bulk_export_group_selector, :generate_bulk_export_sample_preview, :bulk_generated_certificates_list, :generate_bulk_export_pdf, :delete_generated_certificate, :delete_bulk_generated_certificate]
  map.resources :message_templates, :collection=>[:new_message_template, :save_message_template, :edit_message_template, :update_message_template, :delete_message_template, :message_templates, :list_keys_for_template]
  map.resources :id_card_templates, :collection=>[:index,:id_card_templates,:settings,:new_id_card_template,:save_id_card_template, :edit_id_card_template, :update_id_card_template, :delete_id_card_template, :id_card_keys, :download_image, :generate_id_card, :generate_id_card_pdf, :load_id_card_key_form, :generated_id_cards, :list_generated_id_cards, :bulk_export, :bulk_export_group_selector, :batch_students, :department_employees, :generate_bulk_export_pdf_student, :generate_bulk_export_pdf_employee, :generate_bulk_export_pdf_guardian, :generate_bulk_export_sample_preview, :save_bulk_generated_id_card, :generate_bulk_export_pdf, :bulk_generated_id_cards_list, :delete_generated_id_card, :delete_bulk_generated_id_card]
  map.resources :generated_pdfs, :collection=>[:download_pdf]
  map.resources :icse_settings,:collection=>{:settings=>:get,:new_icse_exam_category=>:get,:create_icse_exam_category=>:post,:icse_exam_categories=>:get,:edit_icse_exam_category=>:get,:update_icse_exam_category=>:post,:destroy_icse_exam_category=>[:get,:post],:icse_weightages=>:get,:new_icse_weightage=>:get,:create_icse_weightage=>:post,:edit_icse_weightage=>:get,:update_icse_weightage=>:post,:destroy_icse_weightage=>[:get,:post],:assign_icse_weightages=>:get,:select_subjects=>:get,:select_icse_weightages=>:get,:update_subject_weightages=>:post,:internal_assessment_groups=>:get,:new_ia_group=>:get,:create_ia_group=>:post,:update_ia_group=>:post,:destroy_ia_group=>:get,:assign_ia_groups=>:get,:ia_group_subjects=>:get,:select_ia_groups=>:get,:update_subject_ia_groups=>:post,:ia_settings=>[:get,:put],:ia_average_example=>:get,:ia_total_example=>:get},:member=>{:edit_ia_group=>:get}
  map.resources :icse_report_settings,:collection=>{:settings=>[:get,:post]},:only=>[:settings]
  map.resources :ia_scores,:collection=>{:update_ia_score=>:post}
  map.resources :icse_reports,:collection=>{:previous_batch_exam_reports=>:get,:index=>:get,:generate_reports=>[:get,:post],:student_wise_report=>[:get,:post],:student_report=>:post,:student_report_pdf=>:get,:student_transcript=>[:get,:post],:subject_wise_report=>[:get,:post],:list_batches=>:get,:list_subjects=>:get,:list_exam_groups=>:get,:subject_wise_generated_report=>[:get,:post],:internal_and_external_mark_pdf=>:get,:detailed_internal_and_external_mark_pdf=>:get,:internal_and_external_mark_csv=>:get,:detailed_internal_and_external_mark_csv=>:get,:consolidated_report=>:get,:consolidated_generated_report=>[:get,:post],:consolidated_report_csv=>[:get,:post],:student_report_csv=>:get,:batches_ajax=>:get}
  map.resources :news,:collection => { :add => :get,:all=>:get }
  map.resources :reminder_attachments,:member=>{:download=>:get}
  map.resources :record_groups,:collection=>{:manage_record_groups=>[:get,:post],:add_record_groups_to_course=>[:get,:post]} do |record_group|
    record_group.resources :records,:collection=>{:update_priority => [:get,:post]}
  end
  map.resources :tc_template_generate_certificates, :collection=>{:date_in_words=>:get,:generated_certificates=>:get,:transfer_certificate_download=>:get,:preview=>:get},:member=>{:regenerate_certificate=>:get,:edit=>[:get,:post],:preview=>:get}
  map.resources :course_exam_groups,:member=>{:add_exams=>[:get,:post],:update_imported_exams=>[:post,:put],:update_course_exam_group=>[:post]},:collection=>{:list_exam_batches=>[:get]}
  map.resources :student_records,:except=>[:show],:collection=>{:manage_student_records=>[:get,:post],:manage_record_groups_for_students => [:get],:get_courses_list=>[:get],:get_rg_courses_list=>[:get],:manage_student_records_for_course=>[:get],:manage_record_groups_courses=>[:get],:cancel=>[:get],:student_records_for_batch=>[:get,:post]}
  map.resources :student_documents, :member => {:download => [:get]}, :collection => {:documents => [:get]}
  map.resources :student_document_categories, :collection => {:confirm_destroy => [:get]}
  map.resources :assessment_activities
  map.resources :assessments, :member => {:schedule_dates => :get, :save_schedule => [:post, :put], :edit_dates => [:get],:link_attributes => [:get,:post, :put],:activate_exam => [:get,:post], :subject_scores => [:get, :post, :put], :manage_derived_assessment => :get},:collection =>{ :update_profile_info =>:get, :attribute_scores => [:get,:post, :put],  :skill_scores => [:get, :put, :post], :activity_scores => [:get, :post, :put], :exam_timings => :get, :fetch_groups => :get, :fetch_batches => :get, :fetch_timetables => :get, :exam_timings_pdf => :get, :reset_assessments => :post, :unlock_assessments => :post, :unlock_subjects =>:post, :calculate_derived_marks => :get, :activate_subject => :get, :show_derived_mark =>:get}
  map.resources :assessment_attributes
  map.resources :academic_years, :collection => {:set_active => :get, :update_active => :post}, :member => {:fetch_details => :get, :delete_year => :get}
  map.resources :assessment_plans, :member => {:manage_courses => :get, :add_courses => [:get, :put], :unlink_course => :get, :delete_planner_assessment => :delete, :edit_assessment_term => :get, :update_assessment_term => :put, :delete_term => :delete}, :collection => {:delete_assessment_group => :post, :import_planner => [:get, :post], :refresh_from_academic_year => :get, :update_planner_form => :get, :reimport_planner => :post, :import_logs => :get}
  map.resources :grading_profiles, :member => {:add_grades => :get, :update_grades => :put, :fetch_details => :get},:collection => {:set_default => :get, :update_default => :post}
  map.resources :assessment_groups, :collection => {:fetch_profiles => [:get], :new_course_exam => [:get], :course_exam_form => [:get], :create_course_exam => [:post], :change_group_type => :get, :planner_assessment => [:get,:post,:put],:fetch_assessment_groups => [:get],:fetch_final_term_assessment_groups => [:get], :fetch_final_term_assessment_groups_new => [:get]}, :member => {:edit_course_exam  => [:get], :update_course_exam => [:put], :final_term_assessment => [:get, :post], :edit_final_term => :get, :update_final_term => [:put], :create_final_term => :post}
  map.resources :assessment_reports, :member => {:batch_reports => :get}, :collection => {:select_report=> :get,:settings => [:get, :post], :report_header_info => :get, :report_signature_info => :get, :preview => :get, :students_term_reports => :get, :refresh_students => :get, :refresh_report => :get,:student_term_report_pdf => :get, :generate_exam_reports => [:get, :post, :put], :generate_term_reports => [:get, :post, :put],:generate_planner_reports => [:get, :post, :put], :regenerate_reports => :get, :student_exam_reports => :get, :student_exam_report_pdf => :get, :publish_reports => :get, :students_planner_reports => :get, :student_plan_report_pdf => :get, :generate_batch_wise_reports => :post, :advanced_report_settings => [:get, :post], :attendance_settings => [:get,:post], :records_and_remarks_settings => [:get, :post], :load_record_items => :get, :manage_links=>:get, :reorder_assessments=>[:put,:post], :fetch_templates => :get, :template_preview => :get, :preview_img => :get, :general_settings => :get }
  map.resources :remark_banks, :member => {:show => [:get,:post],:destroy => :delete, :edit => [:get,:post], :update => [:put]}, :collection => {:index => :get, :create => :post,:new => :get}
  map.resources :gradebook_remarks, :member => {:manage => [:get], :update_report_type => [:post], :update_reportable => [:post], :update_remark_type => [:post], :update_remarkable => [:post], :update_student_list => [:post], :add_from_remark_bank => [:post], :update_remark_templates => [:post], :update_remark_preview => [:post],:update_remark => [:post, :put]}#, :collection => {:update_remark => [:post, :put]}
  map.resources :custom_words
  map.resources :subject_skill_sets, :memeber => {:add_skills => :get, :update_skills => :put, :add_sub_skills => :get, :update_sub_skills => :put}
  map.resources :finance_settings, :member => {:configure_category => [:get, :post] },
    :collection => {:fee_general_settings => [:get,:post], :fee_settings => :get,
    :receipt_pdf_settings => [:get, :post], :receipt_print_settings => [:get, :put],
    :fees_receipt_preview => [:get]}
  map.resources :fee_accounts, :collection => [:manage]
  map.resources :financial_years, :collection => {:set_active => :get, :update_active => :post}, :member => {:fetch_details => :get, :delete_year => :get}
  map.resources :receipt_sets
  map.resources :receipt_templates, :member => [:template_preview], :collection => []
  map.resources :leave_years, :collection => {:set_active => :get, :update_active => :post,:autocredit_setting => :get, :leave_process_settings => :get,:credit_date_setting => :get,:leave_credit_date_settings => :post,:reset_setting => :get, :leave_reset_settings => [:post, :get],:confirmation_box => :get,:retry_employee_reset => :post ,:leave_process => :get, :process_leaves => :get, :settings => :post, :leave_records => :get, :leave_record_filter => :get}, :member => {:fetch_details => :get, :delete_year => :get, :end_year_process_detail => :get, :retry_reset => :post}
  
  map.root :controller => 'user', :action => 'login'  
  
  map.resources :master_fees, :only => [:index],
                :member => {:edit_master_particular => :get, :update_master_particular => :put,
                            :delete_master_particular => :delete, :edit_master_discount => :get,
                            :update_master_discount => :put, :delete_master_discount => :delete},
                :collection => {:new_master_particular => :get, :create_master_particular => :post,
                                :new_master_discount => :get, :create_master_discount => :post,
                                :manage_masters => [:get, :post]}
  map.resources :finance_reports, :only => [:index],
                :collection => {:payment_mode_summary => :get, :particular_wise_daily => :get,
                                :particular_wise_student_transaction => :get}

  

  #  map.fa_scores 'assessment_scores/subject/:subject_id/cce_exam_category/:cce_exam_category_id/fa_group/:fa_group_id', :controller=>'assessment_scores',:action=>'fa_scores'
  map.observation_groups_assessment_scores 'batch/:batch_id/assessment_scores/observation_groups', :controller=>'assessment_scores',:action=>'observation_groups'
  map.upscale_scores_cce_report_settings 'batch/:batch_id/cce_report_settings/upscale_scores', :controller=>'cce_report_settings',:action=>'upscale_scores'
  map.previous_marks_entry 'batch/:batch_id/previous_exam_marks/exam_group/:exam_group_id', :controller=>'exam',:action=>'previous_exam_marks'
  #  map.fa_scores_with_out_exam 'assessment_scores/subject/:subject_id/cce_exam_category/:cce_exam_category_id/fa_group/:fa_group_id/exam_group/:exam_group_id', :controller=>'assessment_scores',:action=>'fa_scores'
  #  map.subject_fa_groups 'assessment_scores/subject/:subject_id/cce_exam_category/:cce_exam_category_id', :controller=>'assessment_scores',:action=>'exam_fa_groups'
  #  map.subject_fa_groups_without_exam 'assessment_scores/subject/:subject_id/cce_exam_category/:cce_exam_category_id/exam_group/:exam_group_id', :controller=>'assessment_scores',:action=>'exam_fa_groups'
  map.exam_group_fa_scores 'exam_group/:exam_group_id/fa_scores', :controller=>'assessment_scores',:action=>'fa_scores'
  map.exam_group_fa_scores_with_fa 'exam_group/:exam_group_id/fa_scores/:fa_group', :controller=>'assessment_scores',:action=>'fa_scores'
  map.subject_fa_scores 'exam_group/:exam_group_id/subject/:subject_id/fa_scores', :controller=>'assessment_scores',:action=>'fa_scores'
  map.observation_scores 'assessment_scores/batch/:batch_id/observation_group/:observation_group_id', :controller=>'assessment_scores',:action=>'observation_scores'
  map.scheduled_task 'scheduled_jobs/:job_object/:job_type',:controller => "scheduled_jobs",:action => "index"
  map.scheduled_task_object 'scheduled_jobs/:job_object',:controller => "scheduled_jobs",:action => "index"

  map.ia_scores 'ia_scores/exam/:exam_id/ia_scores', :controller=>'ia_scores',:action=>'ia_scores'


  map.namespace(:api) do |api|
    api.resources :attendances, :requirements => {:id => /[A-Z0-9]{1,}([\/_-]{1}[A-Z0-9]{1,})*/i}
    api.resources :employee_attendances
    api.resources :courses
    api.resources :batches
    api.resources :schools
    api.resources :students,:member => {:fee_dues => :get,:upload_photo => [:post]},:collection => {:fee_dues_profile => :get,:attendance_profile => :get,:exam_report_profile => :get,:student_structure => :get}, :requirements => {:id => /[A-Z0-9]{1,}([\/_-]{1}[A-Z0-9]{1,})*/i}
    api.resources :employees,:member => {:upload_photo => [:post]},:collection => {:leave_profile => :get,:employee_structure => :get}, :requirements => {:id => /[A-Z0-9]{1,}([\/_-]{1}[A-Z0-9]{1,})*/i}
    api.resources :employee_departments
    api.resources :finance_transactions
    api.resources :users, :requirements => {:id => /[A-Z0-9]{1,}([\/_-]{1}[A-Z0-9]{1,})*/i}
    api.resources :news
    #    api.resources :reminders
    api.resources :subjects
    api.resources :student_categories
    api.resources :student_documents, :only => [:create, :destroy, :edit], :collection => {:documents => :get}
    api.resources :student_document_categories, :only => [:index, :create, :edit]
    api.resources :events
    api.resources :employee_leave_types
    api.resources :leave_groups
    api.resources :payroll, :member => {:view_payroll => [:get]}
    api.resources :payroll_groups
    api.resources :timetables
    api.resources :exam_groups
    api.resources :exam_scores
    api.resources :grading_levels
    api.resources :employee_grades
    api.resources :employee_positions
    api.resources :employee_categories
    api.resources :biometric_informations
    api.connect 'exam_scores/:id',:controller => 'exam_scores', :action => 'update'
  end
  #  map.connect ":class/:id/:attachment/image", :action => "paperclip_attachment", :controller => "user"
  map.connect 'user/profile/*user_name', :controller=>:user, :action => :profile
  map.connect 'user/user_change_password/*user_name', :controller=>:user, :action => :user_change_password
  map.connect 'user/edit_privilege/*user_name', :controller=>:user, :action => :edit_privilege
  map.connect 'employee/edit_privilege/*user_name', :controller=>:employee, :action=>:edit_privilege
  map.connect 'reports/:action', :controller=>:report
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action'
  map.connect ':controller/:action/:id/:id2'
  map.connect ':controller/:action/:id.:format'

end
