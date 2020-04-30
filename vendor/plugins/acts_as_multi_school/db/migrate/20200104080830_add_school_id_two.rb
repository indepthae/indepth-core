class AddSchoolIdTwo < ActiveRecord::Migration
  def self.up
      add_column :employee_positions, :school_id, :integer
      add_column :employee_leaves, :school_id, :integer
      add_column :apply_leaves, :school_id, :integer
      add_column :employee_leave_types, :school_id, :integer
      add_column :employee_bank_details, :school_id, :integer
      add_column :employee_salary_structures, :school_id, :integer
      add_column :employee_departments, :school_id, :integer
      add_column :employee_categories, :school_id, :integer
      add_column :individual_payslip_categories, :school_id, :integer
      add_column :monthly_payslips, :school_id, :integer
      add_column :employee_department_events, :school_id, :integer
      add_column :bank_fields, :school_id, :integer
      add_column :employees_subjects, :school_id, :integer
      add_column :employee_attendances, :school_id, :integer
      add_column :employee_additional_details, :school_id, :integer
      add_column :student_previous_subject_marks, :school_id, :integer
      add_column :exam_groups, :school_id, :integer
      add_column :archived_exam_scores, :school_id, :integer
      add_column :courses, :school_id, :integer
      add_column :archived_guardians, :school_id, :integer
      add_column :student_categories, :school_id, :integer
      add_column :news_comments, :school_id, :integer
      add_column :additional_fields, :school_id, :integer
      add_column :subjects, :school_id, :integer
      add_column :archived_employee_bank_details, :school_id, :integer
      add_column :grading_levels, :school_id, :integer
      add_column :batches, :school_id, :integer
      add_column :student_additional_details, :school_id, :integer
      add_column :exams, :school_id, :integer
      add_column :weekdays, :school_id, :integer
      add_column :electives, :school_id, :integer
      add_column :archived_employee_salary_structures, :school_id, :integer
      add_column :archived_employee_salary_structure_components, :school_id, :integer
      add_column :configurations, :school_id, :integer
      add_column :grouped_exams, :school_id, :integer
      add_column :student_previous_datas, :school_id, :integer
      add_column :batch_events, :school_id, :integer
      add_column :period_entries, :school_id, :integer
      add_column :guardians, :school_id, :integer
      add_column :timetable_entries, :school_id, :integer
      add_column :student_additional_fields, :school_id, :integer
      add_column :events, :school_id, :integer
      add_column :archived_employee_additional_details, :school_id, :integer
      add_column :finance_transaction_triggers, :school_id, :integer
      add_column :finance_fee_categories, :school_id, :integer
      add_column :liabilities, :school_id, :integer
      add_column :news, :school_id, :integer
      add_column :news_attachments, :school_id, :integer
      add_column :elective_groups, :school_id, :integer
      add_column :fee_discounts, :school_id, :integer
      add_column :finance_fee_collections, :school_id, :integer
      add_column :fee_collection_particulars, :school_id, :integer
      add_column :finance_fee_structure_elements, :school_id, :integer
      add_column :finance_donations, :school_id, :integer
      add_column :assets, :school_id, :integer
      add_column :user_events, :school_id, :integer
      add_column :finance_fee_particulars, :school_id, :integer
      add_column :sms_settings, :school_id, :integer
      add_column :class_timings, :school_id, :integer
      add_column :fee_collection_discounts, :school_id, :integer
      add_column :reminders, :school_id, :integer
      add_column :reminder_attachments, :school_id, :integer
      add_column :reminder_attachment_relations, :school_id, :integer
      add_column :students_subjects, :school_id, :integer
      add_column :finance_transaction_categories, :school_id, :integer
      add_column :exam_scores, :school_id, :integer
      add_column :finance_fees, :school_id, :integer
      add_column :attendances, :school_id, :integer
      add_column :employee_grades, :school_id, :integer
      add_column :timetables, :school_id, :integer
      add_column :subject_leaves, :school_id, :integer
      add_column :sms_messages, :school_id, :integer
      add_column :sms_logs, :school_id, :integer
      add_column :batch_groups, :school_id, :integer
      add_column :class_designations, :school_id, :integer
      add_column :grouped_batches, :school_id, :integer
      add_column :grouped_exam_reports, :school_id, :integer
      add_column :previous_exam_scores, :school_id, :integer
      add_column :ranking_levels, :school_id, :integer
      add_column :assessment_scores, :school_id, :integer
      add_column :cce_exam_categories, :school_id, :integer
      add_column :cce_grades, :school_id, :integer
      add_column :cce_grade_sets, :school_id, :integer
      add_column :cce_reports, :school_id, :integer
      add_column :cce_weightages, :school_id, :integer
      add_column :descriptive_indicators, :school_id, :integer
      add_column :fa_criterias, :school_id, :integer
      add_column :fa_groups, :school_id, :integer
      add_column :observation_groups, :school_id, :integer
      add_column :observations, :school_id, :integer
      add_column :additional_field_options, :school_id, :integer
      add_column :batch_students, :school_id, :integer
      add_column :student_additional_field_options, :school_id, :integer
      add_column :subject_amounts, :school_id, :integer
      add_column :weekday_sets_weekdays, :school_id, :integer
      add_column :weekday_sets, :school_id, :integer
      add_column :time_table_weekdays, :school_id, :integer
      add_column :time_table_class_timings, :school_id, :integer
      add_column :class_timing_sets, :school_id, :integer
      add_column :biometric_informations, :school_id, :integer
      add_column :user_menu_links, :school_id, :integer
      add_column :timetable_swaps, :school_id, :integer
      add_column :fines, :school_id, :integer
      add_column :fine_rules, :school_id, :integer
      add_column :fee_refunds, :school_id, :integer
      add_column :refund_rules, :school_id, :integer
      add_column :collection_particulars, :school_id, :integer
      add_column :collection_discounts, :school_id, :integer
      add_column :fee_transactions, :school_id, :integer
      add_column :fee_collection_batches, :school_id, :integer
      add_column :category_batches, :school_id, :integer
      add_column :additional_report_csvs, :school_id, :integer
      add_column :redactor_uploads, :school_id, :integer
      add_column :allocated_classrooms, :school_id, :integer
      add_column :buildings, :school_id, :integer
      add_column :classrooms, :school_id, :integer
      add_column :classroom_allocations, :school_id, :integer
      add_column :ia_calculations, :school_id, :integer
      add_column :ia_groups, :school_id, :integer
      add_column :ia_indicators, :school_id, :integer
      add_column :ia_scores, :school_id, :integer
      add_column :icse_exam_categories, :school_id, :integer
      add_column :icse_reports, :school_id, :integer
      add_column :icse_weightages, :school_id, :integer
      add_column :remarks, :school_id, :integer
      add_column :remark_parameters, :school_id, :integer
      add_column :multi_fees_transactions, :school_id, :integer
      add_column :particular_payments, :school_id, :integer
      add_column :particular_discounts, :school_id, :integer
      add_column :attendance_weekday_sets, :school_id, :integer
      add_column :discount_particular_logs, :school_id, :integer
      add_column :batch_class_timing_sets, :school_id, :integer
      add_column :time_table_class_timing_sets, :school_id, :integer
      add_column :donation_additional_details, :school_id, :integer
      add_column :donation_additional_fields, :school_id, :integer
      add_column :donation_additional_field_options, :school_id, :integer
      add_column :record_groups, :school_id, :integer
      add_column :records, :school_id, :integer
      add_column :record_field_options, :school_id, :integer
      add_column :record_addl_attachments, :school_id, :integer
      add_column :record_assignments, :school_id, :integer
      add_column :record_batch_assignments, :school_id, :integer
      add_column :student_records, :school_id, :integer
      add_column :cce_report_settings, :school_id, :integer
      add_column :cce_report_setting_copies, :school_id, :integer
      add_column :asl_scores, :school_id, :integer
      add_column :upscale_scores, :school_id, :integer
      add_column :cbse_co_scholastic_settings, :school_id, :integer
      add_column :eiop_settings, :school_id, :integer
      add_column :employee_additional_leaves, :school_id, :integer
      add_column :leave_resets, :school_id, :integer
      add_column :leave_reset_logs, :school_id, :integer
      add_column :payslip_settings, :school_id, :integer
      add_column :employee_payslips, :school_id, :integer
      add_column :employee_lops, :school_id, :integer
      add_column :employee_overtimes, :school_id, :integer
      add_column :employee_payslip_categories, :school_id, :integer
      add_column :employee_salary_structure_components, :school_id, :integer
      add_column :formula_and_conditions, :school_id, :integer
      add_column :hr_formulas, :school_id, :integer
      add_column :payroll_group_revisions, :school_id, :integer
      add_column :payroll_groups_payroll_categories, :school_id, :integer
      add_column :payslips_date_ranges, :school_id, :integer
      add_column :salary_working_days, :school_id, :integer
      add_column :hr_seed_errors_logs, :school_id, :integer
      add_column :payslip_additional_leaves, :school_id, :integer
      add_column :hr_reports, :school_id, :integer
      add_column :icse_report_settings, :school_id, :integer
      add_column :icse_report_setting_copies, :school_id, :integer
      add_column :report_settings, :school_id, :integer
      add_column :exam_group_fa_statuses, :school_id, :integer
      add_column :student_coscholastic_remarks, :school_id, :integer
      add_column :student_coscholastic_remark_copies, :school_id, :integer
      add_column :observation_remarks, :school_id, :integer
      add_column :student_attachments, :school_id, :integer
      add_column :student_attachment_categories, :school_id, :integer
      add_column :student_attachment_records, :school_id, :integer
      add_column :lop_prorated_formulas, :school_id, :integer
      add_column :payroll_revisions, :school_id, :integer
      add_column :feature_access_settings, :school_id, :integer
      add_column :message_threads, :school_id, :integer
      add_column :messages, :school_id, :integer
      add_column :message_recipients, :school_id, :integer
      add_column :message_attachments, :school_id, :integer
      add_column :message_settings, :school_id, :integer
      add_column :notifications, :school_id, :integer
      add_column :notification_recipients, :school_id, :integer
      add_column :leave_groups, :school_id, :integer
      add_column :leave_group_leave_types, :school_id, :integer
      add_column :leave_group_employees, :school_id, :integer
      add_column :academic_years, :school_id, :integer
      add_column :assessment_plans, :school_id, :integer
      add_column :assessment_terms, :school_id, :integer
      add_column :assessment_groups, :school_id, :integer
      add_column :assessment_schedules, :school_id, :integer
      add_column :subject_assessments, :school_id, :integer
      add_column :assessment_activities, :school_id, :integer
      add_column :assessment_activity_profiles, :school_id, :integer
      add_column :grades, :school_id, :integer
      add_column :grade_sets, :school_id, :integer
      add_column :assessment_attribute_profiles, :school_id, :integer
      add_column :assessment_attributes, :school_id, :integer
      add_column :assessment_plans_courses, :school_id, :integer
      add_column :assessment_group_batches, :school_id, :integer
      add_column :activity_assessments, :school_id, :integer
      add_column :attribute_assessments, :school_id, :integer
      add_column :assessment_marks, :school_id, :integer
      add_column :assessment_report_settings, :school_id, :integer
      add_column :derived_assessment_group_settings, :school_id, :integer
      add_column :converted_assessment_marks, :school_id, :integer
      add_column :individual_reports, :school_id, :integer
      add_column :generated_reports, :school_id, :integer
      add_column :generated_report_batches, :school_id, :integer
      add_column :derived_assessment_groups_associations, :school_id, :integer
      add_column :message_attachments_assocs, :school_id, :integer
      add_column :assessment_report_setting_copies, :school_id, :integer
      add_column :subject_attribute_assessments, :school_id, :integer
      add_column :override_assessment_marks, :school_id, :integer
      add_column :collectible_tax_slabs, :school_id, :integer
      add_column :tax_assignments, :school_id, :integer
      add_column :tax_collections, :school_id, :integer
      add_column :tax_payments, :school_id, :integer
      add_column :tax_slabs, :school_id, :integer
      add_column :finance_transaction_fines, :school_id, :integer
      add_column :multi_fee_discounts, :school_id, :integer
      add_column :multi_transaction_fines, :school_id, :integer
      add_column :custom_translations, :school_id, :integer
      add_column :assessment_plan_imports, :school_id, :integer
      add_column :job_resource_locators, :school_id, :integer
      add_column :assessment_score_imports, :school_id, :integer
      add_column :course_subjects, :school_id, :integer
      add_column :subject_groups, :school_id, :integer
      add_column :course_elective_groups, :school_id, :integer
      add_column :subject_skill_sets, :school_id, :integer
      add_column :subject_skills, :school_id, :integer
      add_column :skill_assessments, :school_id, :integer
      add_column :batch_subject_groups, :school_id, :integer
      add_column :assessment_dates, :school_id, :integer
      add_column :gradebook_attendances, :school_id, :integer
      add_column :fee_accounts, :school_id, :integer
      add_column :fee_receipt_templates, :school_id, :integer
      add_column :finance_category_accounts, :school_id, :integer
      add_column :finance_category_receipt_templates, :school_id, :integer
      add_column :finance_category_receipt_sets, :school_id, :integer
      add_column :subject_imports, :school_id, :integer
      add_column :individual_report_pdfs, :school_id, :integer
      add_column :gradebook_record_groups, :school_id, :integer
      add_column :gradebook_records, :school_id, :integer
      add_column :leave_years, :school_id, :integer
      add_column :leave_credits, :school_id, :integer
      add_column :leave_credit_logs, :school_id, :integer
      add_column :attendance_labels, :school_id, :integer
      add_column :fine_cancel_trackers, :school_id, :integer
      add_column :additional_report_pdfs, :school_id, :integer
      add_column :user_groups, :school_id, :integer
      add_column :user_groups_users, :school_id, :integer
      add_column :advance_fee_categories, :school_id, :integer
      add_column :advance_fee_category_batches, :school_id, :integer
      add_column :advance_fee_category_collections, :school_id, :integer
      add_column :advance_fee_wallets, :school_id, :integer
      add_column :advance_fee_collections, :school_id, :integer
      add_column :advance_fee_deductions, :school_id, :integer
      add_column :cancelled_advance_fee_transactions, :school_id, :integer
      add_column :marked_attendance_records, :school_id, :integer
      add_column :attendance_settings, :school_id, :integer
      add_column :leave_auto_credit_records, :school_id, :integer
      add_column :course_transcript_settings, :school_id, :integer
  
      add_index :employee_positions, :school_id
      add_index :employee_leaves, :school_id
      add_index :apply_leaves, :school_id
      add_index :employee_leave_types, :school_id
      add_index :employee_bank_details, :school_id
      add_index :employee_salary_structures, :school_id
      add_index :employee_departments, :school_id
      add_index :employee_categories, :school_id
      add_index :individual_payslip_categories, :school_id
      add_index :monthly_payslips, :school_id
      add_index :employee_department_events, :school_id
      add_index :bank_fields, :school_id
      add_index :employees_subjects, :school_id
      add_index :employee_attendances, :school_id
      add_index :employee_additional_details, :school_id
      add_index :student_previous_subject_marks, :school_id
      add_index :exam_groups, :school_id
      add_index :archived_exam_scores, :school_id
      add_index :courses, :school_id
      add_index :archived_guardians, :school_id
      add_index :student_categories, :school_id
      add_index :news_comments, :school_id
      add_index :additional_fields, :school_id
      add_index :subjects, :school_id
      add_index :archived_employee_bank_details, :school_id
      add_index :grading_levels, :school_id
      add_index :batches, :school_id
      add_index :student_additional_details, :school_id
      add_index :exams, :school_id
      add_index :weekdays, :school_id
      add_index :electives, :school_id
      add_index :archived_employee_salary_structures, :school_id
      add_index :archived_employee_salary_structure_components, :school_id
      add_index :configurations, :school_id
      add_index :grouped_exams, :school_id
      add_index :student_previous_datas, :school_id
      add_index :batch_events, :school_id
      add_index :period_entries, :school_id
      add_index :guardians, :school_id
      add_index :timetable_entries, :school_id
      add_index :student_additional_fields, :school_id
      add_index :events, :school_id
      add_index :archived_employee_additional_details, :school_id
      add_index :finance_transaction_triggers, :school_id
      add_index :finance_fee_categories, :school_id
      add_index :liabilities, :school_id
      add_index :news, :school_id
      add_index :news_attachments, :school_id
      add_index :elective_groups, :school_id
      add_index :fee_discounts, :school_id
      add_index :finance_fee_collections, :school_id
      add_index :fee_collection_particulars, :school_id
      add_index :finance_fee_structure_elements, :school_id
      add_index :finance_donations, :school_id
      add_index :assets, :school_id
      add_index :user_events, :school_id
      add_index :finance_fee_particulars, :school_id
      add_index :sms_settings, :school_id
      add_index :class_timings, :school_id
      add_index :fee_collection_discounts, :school_id
      add_index :reminders, :school_id
      add_index :reminder_attachments, :school_id
      add_index :reminder_attachment_relations, :school_id
      add_index :students_subjects, :school_id
      add_index :finance_transaction_categories, :school_id
      add_index :exam_scores, :school_id
      add_index :finance_fees, :school_id
      add_index :attendances, :school_id
      add_index :employee_grades, :school_id
      add_index :timetables, :school_id
      add_index :subject_leaves, :school_id
      add_index :sms_messages, :school_id
      add_index :sms_logs, :school_id
      add_index :batch_groups, :school_id
      add_index :class_designations, :school_id
      add_index :grouped_batches, :school_id
      add_index :grouped_exam_reports, :school_id
      add_index :previous_exam_scores, :school_id
      add_index :ranking_levels, :school_id
      add_index :assessment_scores, :school_id
      add_index :cce_exam_categories, :school_id
      add_index :cce_grades, :school_id
      add_index :cce_grade_sets, :school_id
      add_index :cce_reports, :school_id
      add_index :cce_weightages, :school_id
      add_index :descriptive_indicators, :school_id
      add_index :fa_criterias, :school_id
      add_index :fa_groups, :school_id
      add_index :observation_groups, :school_id
      add_index :observations, :school_id
      add_index :additional_field_options, :school_id
      add_index :batch_students, :school_id
      add_index :student_additional_field_options, :school_id
      add_index :subject_amounts, :school_id
      add_index :weekday_sets_weekdays, :school_id
      add_index :weekday_sets, :school_id
      add_index :time_table_weekdays, :school_id
      add_index :time_table_class_timings, :school_id
      add_index :class_timing_sets, :school_id
      add_index :biometric_informations, :school_id
      add_index :user_menu_links, :school_id
      add_index :timetable_swaps, :school_id
      add_index :fines, :school_id
      add_index :fine_rules, :school_id
      add_index :fee_refunds, :school_id
      add_index :refund_rules, :school_id
      add_index :collection_particulars, :school_id
      add_index :collection_discounts, :school_id
      add_index :fee_transactions, :school_id
      add_index :fee_collection_batches, :school_id
      add_index :category_batches, :school_id
      add_index :additional_report_csvs, :school_id
      add_index :redactor_uploads, :school_id
      add_index :allocated_classrooms, :school_id
      add_index :buildings, :school_id
      add_index :classrooms, :school_id
      add_index :classroom_allocations, :school_id
      add_index :ia_calculations, :school_id
      add_index :ia_groups, :school_id
      add_index :ia_indicators, :school_id
      add_index :ia_scores, :school_id
      add_index :icse_exam_categories, :school_id
      add_index :icse_reports, :school_id
      add_index :icse_weightages, :school_id
      add_index :remarks, :school_id
      add_index :remark_parameters, :school_id
      add_index :multi_fees_transactions, :school_id
      add_index :particular_payments, :school_id
      add_index :particular_discounts, :school_id
      add_index :attendance_weekday_sets, :school_id
      add_index :discount_particular_logs, :school_id
      add_index :batch_class_timing_sets, :school_id
      add_index :time_table_class_timing_sets, :school_id
      add_index :donation_additional_details, :school_id
      add_index :donation_additional_fields, :school_id
      add_index :donation_additional_field_options, :school_id
      add_index :record_groups, :school_id
      add_index :records, :school_id
      add_index :record_field_options, :school_id
      add_index :record_addl_attachments, :school_id
      add_index :record_assignments, :school_id
      add_index :record_batch_assignments, :school_id
      add_index :student_records, :school_id
      add_index :cce_report_settings, :school_id
      add_index :cce_report_setting_copies, :school_id
      add_index :asl_scores, :school_id
      add_index :upscale_scores, :school_id
      add_index :cbse_co_scholastic_settings, :school_id
      add_index :eiop_settings, :school_id
      add_index :employee_additional_leaves, :school_id
      add_index :leave_resets, :school_id
      add_index :leave_reset_logs, :school_id
      add_index :payslip_settings, :school_id
      add_index :employee_payslips, :school_id
      add_index :employee_lops, :school_id
      add_index :employee_overtimes, :school_id
      add_index :employee_payslip_categories, :school_id
      add_index :employee_salary_structure_components, :school_id
      add_index :formula_and_conditions, :school_id
      add_index :hr_formulas, :school_id
      add_index :payroll_group_revisions, :school_id
      add_index :payroll_groups_payroll_categories, :school_id
      add_index :payslips_date_ranges, :school_id
      add_index :salary_working_days, :school_id
      add_index :hr_seed_errors_logs, :school_id
      add_index :payslip_additional_leaves, :school_id
      add_index :hr_reports, :school_id
      add_index :icse_report_settings, :school_id
      add_index :icse_report_setting_copies, :school_id
      add_index :report_settings, :school_id
      add_index :exam_group_fa_statuses, :school_id
      add_index :student_coscholastic_remarks, :school_id
      add_index :student_coscholastic_remark_copies, :school_id
      add_index :observation_remarks, :school_id
      add_index :student_attachments, :school_id
      add_index :student_attachment_categories, :school_id
      add_index :student_attachment_records, :school_id
      add_index :lop_prorated_formulas, :school_id
      add_index :payroll_revisions, :school_id
      add_index :feature_access_settings, :school_id
      add_index :message_threads, :school_id
      add_index :messages, :school_id
      add_index :message_recipients, :school_id
      add_index :message_attachments, :school_id
      add_index :message_settings, :school_id
      add_index :notifications, :school_id
      add_index :notification_recipients, :school_id
      add_index :leave_groups, :school_id
      add_index :leave_group_leave_types, :school_id
      add_index :leave_group_employees, :school_id
      add_index :academic_years, :school_id
      add_index :assessment_plans, :school_id
      add_index :assessment_terms, :school_id
      add_index :assessment_groups, :school_id
      add_index :assessment_schedules, :school_id
      add_index :subject_assessments, :school_id
      add_index :assessment_activities, :school_id
      add_index :assessment_activity_profiles, :school_id
      add_index :grades, :school_id
      add_index :grade_sets, :school_id
      add_index :assessment_attribute_profiles, :school_id
      add_index :assessment_attributes, :school_id
      add_index :assessment_plans_courses, :school_id
      add_index :assessment_group_batches, :school_id
      add_index :activity_assessments, :school_id
      add_index :attribute_assessments, :school_id
      add_index :assessment_marks, :school_id
      add_index :assessment_report_settings, :school_id
      add_index :derived_assessment_group_settings, :school_id
      add_index :converted_assessment_marks, :school_id
      add_index :individual_reports, :school_id
      add_index :generated_reports, :school_id
      add_index :generated_report_batches, :school_id
      add_index :derived_assessment_groups_associations, :school_id
      add_index :message_attachments_assocs, :school_id
      add_index :assessment_report_setting_copies, :school_id
      add_index :subject_attribute_assessments, :school_id
      add_index :override_assessment_marks, :school_id
      add_index :collectible_tax_slabs, :school_id
      add_index :tax_assignments, :school_id
      add_index :tax_collections, :school_id
      add_index :tax_payments, :school_id
      add_index :tax_slabs, :school_id
      add_index :finance_transaction_fines, :school_id
      add_index :multi_fee_discounts, :school_id
      add_index :multi_transaction_fines, :school_id
      add_index :custom_translations, :school_id
      add_index :assessment_plan_imports, :school_id
      add_index :job_resource_locators, :school_id
      add_index :assessment_score_imports, :school_id
      add_index :course_subjects, :school_id
      add_index :subject_groups, :school_id
      add_index :course_elective_groups, :school_id
      add_index :subject_skill_sets, :school_id
      add_index :subject_skills, :school_id
      add_index :skill_assessments, :school_id
      add_index :batch_subject_groups, :school_id
      add_index :assessment_dates, :school_id
      add_index :gradebook_attendances, :school_id
      add_index :fee_accounts, :school_id
      add_index :fee_receipt_templates, :school_id
      add_index :finance_category_accounts, :school_id
      add_index :finance_category_receipt_templates, :school_id
      add_index :finance_category_receipt_sets, :school_id
      add_index :subject_imports, :school_id
      add_index :individual_report_pdfs, :school_id
      add_index :gradebook_record_groups, :school_id
      add_index :gradebook_records, :school_id
      add_index :leave_years, :school_id
      add_index :leave_credits, :school_id
      add_index :leave_credit_logs, :school_id
      add_index :attendance_labels, :school_id
      add_index :fine_cancel_trackers, :school_id
      add_index :additional_report_pdfs, :school_id
      add_index :user_groups, :school_id
      add_index :user_groups_users, :school_id
      add_index :advance_fee_categories, :school_id
      add_index :advance_fee_category_batches, :school_id
      add_index :advance_fee_category_collections, :school_id
      add_index :advance_fee_wallets, :school_id
      add_index :advance_fee_collections, :school_id
      add_index :advance_fee_deductions, :school_id
      add_index :cancelled_advance_fee_transactions, :school_id
      add_index :marked_attendance_records, :school_id
      add_index :attendance_settings, :school_id
      add_index :leave_auto_credit_records, :school_id
      add_index :course_transcript_settings, :school_id
    end

  def self.down
      remove_index :employee_positions, :school_id
      remove_index :employee_leaves, :school_id
      remove_index :apply_leaves, :school_id
      remove_index :employee_leave_types, :school_id
      remove_index :employee_bank_details, :school_id
      remove_index :employee_salary_structures, :school_id
      remove_index :employee_departments, :school_id
      remove_index :employee_categories, :school_id
      remove_index :individual_payslip_categories, :school_id
      remove_index :monthly_payslips, :school_id
      remove_index :employee_department_events, :school_id
      remove_index :bank_fields, :school_id
      remove_index :employees_subjects, :school_id
      remove_index :employee_attendances, :school_id
      remove_index :employee_additional_details, :school_id
      remove_index :student_previous_subject_marks, :school_id
      remove_index :exam_groups, :school_id
      remove_index :archived_exam_scores, :school_id
      remove_index :courses, :school_id
      remove_index :archived_guardians, :school_id
      remove_index :student_categories, :school_id
      remove_index :news_comments, :school_id
      remove_index :additional_fields, :school_id
      remove_index :subjects, :school_id
      remove_index :archived_employee_bank_details, :school_id
      remove_index :grading_levels, :school_id
      remove_index :batches, :school_id
      remove_index :student_additional_details, :school_id
      remove_index :exams, :school_id
      remove_index :weekdays, :school_id
      remove_index :electives, :school_id
      remove_index :archived_employee_salary_structures, :school_id
      remove_index :archived_employee_salary_structure_components, :school_id
      remove_index :configurations, :school_id
      remove_index :grouped_exams, :school_id
      remove_index :student_previous_datas, :school_id
      remove_index :batch_events, :school_id
      remove_index :period_entries, :school_id
      remove_index :guardians, :school_id
      remove_index :timetable_entries, :school_id
      remove_index :student_additional_fields, :school_id
      remove_index :events, :school_id
      remove_index :archived_employee_additional_details, :school_id
      remove_index :finance_transaction_triggers, :school_id
      remove_index :finance_fee_categories, :school_id
      remove_index :liabilities, :school_id
      remove_index :news, :school_id
      remove_index :news_attachments, :school_id
      remove_index :elective_groups, :school_id
      remove_index :fee_discounts, :school_id
      remove_index :finance_fee_collections, :school_id
      remove_index :fee_collection_particulars, :school_id
      remove_index :finance_fee_structure_elements, :school_id
      remove_index :finance_donations, :school_id
      remove_index :assets, :school_id
      remove_index :user_events, :school_id
      remove_index :finance_fee_particulars, :school_id
      remove_index :sms_settings, :school_id
      remove_index :class_timings, :school_id
      remove_index :fee_collection_discounts, :school_id
      remove_index :reminders, :school_id
      remove_index :reminder_attachments, :school_id
      remove_index :reminder_attachment_relations, :school_id
      remove_index :students_subjects, :school_id
      remove_index :finance_transaction_categories, :school_id
      remove_index :exam_scores, :school_id
      remove_index :finance_fees, :school_id
      remove_index :attendances, :school_id
      remove_index :employee_grades, :school_id
      remove_index :timetables, :school_id
      remove_index :subject_leaves, :school_id
      remove_index :sms_messages, :school_id
      remove_index :sms_logs, :school_id
      remove_index :batch_groups, :school_id
      remove_index :class_designations, :school_id
      remove_index :grouped_batches, :school_id
      remove_index :grouped_exam_reports, :school_id
      remove_index :previous_exam_scores, :school_id
      remove_index :ranking_levels, :school_id
      remove_index :assessment_scores, :school_id
      remove_index :cce_exam_categories, :school_id
      remove_index :cce_grades, :school_id
      remove_index :cce_grade_sets, :school_id
      remove_index :cce_reports, :school_id
      remove_index :cce_weightages, :school_id
      remove_index :descriptive_indicators, :school_id
      remove_index :fa_criterias, :school_id
      remove_index :fa_groups, :school_id
      remove_index :observation_groups, :school_id
      remove_index :observations, :school_id
      remove_index :additional_field_options, :school_id
      remove_index :batch_students, :school_id
      remove_index :student_additional_field_options, :school_id
      remove_index :subject_amounts, :school_id
      remove_index :weekday_sets_weekdays, :school_id
      remove_index :weekday_sets, :school_id
      remove_index :time_table_weekdays, :school_id
      remove_index :time_table_class_timings, :school_id
      remove_index :class_timing_sets, :school_id
      remove_index :biometric_informations, :school_id
      remove_index :user_menu_links, :school_id
      remove_index :timetable_swaps, :school_id
      remove_index :fines, :school_id
      remove_index :fine_rules, :school_id
      remove_index :fee_refunds, :school_id
      remove_index :refund_rules, :school_id
      remove_index :collection_particulars, :school_id
      remove_index :collection_discounts, :school_id
      remove_index :fee_transactions, :school_id
      remove_index :fee_collection_batches, :school_id
      remove_index :category_batches, :school_id
      remove_index :additional_report_csvs, :school_id
      remove_index :redactor_uploads, :school_id
      remove_index :allocated_classrooms, :school_id
      remove_index :buildings, :school_id
      remove_index :classrooms, :school_id
      remove_index :classroom_allocations, :school_id
      remove_index :ia_calculations, :school_id
      remove_index :ia_groups, :school_id
      remove_index :ia_indicators, :school_id
      remove_index :ia_scores, :school_id
      remove_index :icse_exam_categories, :school_id
      remove_index :icse_reports, :school_id
      remove_index :icse_weightages, :school_id
      remove_index :remarks, :school_id
      remove_index :remark_parameters, :school_id
      remove_index :multi_fees_transactions, :school_id
      remove_index :particular_payments, :school_id
      remove_index :particular_discounts, :school_id
      remove_index :attendance_weekday_sets, :school_id
      remove_index :discount_particular_logs, :school_id
      remove_index :batch_class_timing_sets, :school_id
      remove_index :time_table_class_timing_sets, :school_id
      remove_index :donation_additional_details, :school_id
      remove_index :donation_additional_fields, :school_id
      remove_index :donation_additional_field_options, :school_id
      remove_index :record_groups, :school_id
      remove_index :records, :school_id
      remove_index :record_field_options, :school_id
      remove_index :record_addl_attachments, :school_id
      remove_index :record_assignments, :school_id
      remove_index :record_batch_assignments, :school_id
      remove_index :student_records, :school_id
      remove_index :cce_report_settings, :school_id
      remove_index :cce_report_setting_copies, :school_id
      remove_index :asl_scores, :school_id
      remove_index :upscale_scores, :school_id
      remove_index :cbse_co_scholastic_settings, :school_id
      remove_index :eiop_settings, :school_id
      remove_index :employee_additional_leaves, :school_id
      remove_index :leave_resets, :school_id
      remove_index :leave_reset_logs, :school_id
      remove_index :payslip_settings, :school_id
      remove_index :employee_payslips, :school_id
      remove_index :employee_lops, :school_id
      remove_index :employee_overtimes, :school_id
      remove_index :employee_payslip_categories, :school_id
      remove_index :employee_salary_structure_components, :school_id
      remove_index :formula_and_conditions, :school_id
      remove_index :hr_formulas, :school_id
      remove_index :payroll_group_revisions, :school_id
      remove_index :payroll_groups_payroll_categories, :school_id
      remove_index :payslips_date_ranges, :school_id
      remove_index :salary_working_days, :school_id
      remove_index :hr_seed_errors_logs, :school_id
      remove_index :payslip_additional_leaves, :school_id
      remove_index :hr_reports, :school_id
      remove_index :icse_report_settings, :school_id
      remove_index :icse_report_setting_copies, :school_id
      remove_index :report_settings, :school_id
      remove_index :exam_group_fa_statuses, :school_id
      remove_index :student_coscholastic_remarks, :school_id
      remove_index :student_coscholastic_remark_copies, :school_id
      remove_index :observation_remarks, :school_id
      remove_index :student_attachments, :school_id
      remove_index :student_attachment_categories, :school_id
      remove_index :student_attachment_records, :school_id
      remove_index :lop_prorated_formulas, :school_id
      remove_index :payroll_revisions, :school_id
      remove_index :feature_access_settings, :school_id
      remove_index :message_threads, :school_id
      remove_index :messages, :school_id
      remove_index :message_recipients, :school_id
      remove_index :message_attachments, :school_id
      remove_index :message_settings, :school_id
      remove_index :notifications, :school_id
      remove_index :notification_recipients, :school_id
      remove_index :leave_groups, :school_id
      remove_index :leave_group_leave_types, :school_id
      remove_index :leave_group_employees, :school_id
      remove_index :academic_years, :school_id
      remove_index :assessment_plans, :school_id
      remove_index :assessment_terms, :school_id
      remove_index :assessment_groups, :school_id
      remove_index :assessment_schedules, :school_id
      remove_index :subject_assessments, :school_id
      remove_index :assessment_activities, :school_id
      remove_index :assessment_activity_profiles, :school_id
      remove_index :grades, :school_id
      remove_index :grade_sets, :school_id
      remove_index :assessment_attribute_profiles, :school_id
      remove_index :assessment_attributes, :school_id
      remove_index :assessment_plans_courses, :school_id
      remove_index :assessment_group_batches, :school_id
      remove_index :activity_assessments, :school_id
      remove_index :attribute_assessments, :school_id
      remove_index :assessment_marks, :school_id
      remove_index :assessment_report_settings, :school_id
      remove_index :derived_assessment_group_settings, :school_id
      remove_index :converted_assessment_marks, :school_id
      remove_index :individual_reports, :school_id
      remove_index :generated_reports, :school_id
      remove_index :generated_report_batches, :school_id
      remove_index :derived_assessment_groups_associations, :school_id
      remove_index :message_attachments_assocs, :school_id
      remove_index :assessment_report_setting_copies, :school_id
      remove_index :subject_attribute_assessments, :school_id
      remove_index :override_assessment_marks, :school_id
      remove_index :collectible_tax_slabs, :school_id
      remove_index :tax_assignments, :school_id
      remove_index :tax_collections, :school_id
      remove_index :tax_payments, :school_id
      remove_index :tax_slabs, :school_id
      remove_index :finance_transaction_fines, :school_id
      remove_index :multi_fee_discounts, :school_id
      remove_index :multi_transaction_fines, :school_id
      remove_index :custom_translations, :school_id
      remove_index :assessment_plan_imports, :school_id
      remove_index :job_resource_locators, :school_id
      remove_index :assessment_score_imports, :school_id
      remove_index :course_subjects, :school_id
      remove_index :subject_groups, :school_id
      remove_index :course_elective_groups, :school_id
      remove_index :subject_skill_sets, :school_id
      remove_index :subject_skills, :school_id
      remove_index :skill_assessments, :school_id
      remove_index :batch_subject_groups, :school_id
      remove_index :assessment_dates, :school_id
      remove_index :gradebook_attendances, :school_id
      remove_index :fee_accounts, :school_id
      remove_index :fee_receipt_templates, :school_id
      remove_index :finance_category_accounts, :school_id
      remove_index :finance_category_receipt_templates, :school_id
      remove_index :finance_category_receipt_sets, :school_id
      remove_index :subject_imports, :school_id
      remove_index :individual_report_pdfs, :school_id
      remove_index :gradebook_record_groups, :school_id
      remove_index :gradebook_records, :school_id
      remove_index :leave_years, :school_id
      remove_index :leave_credits, :school_id
      remove_index :leave_credit_logs, :school_id
      remove_index :attendance_labels, :school_id
      remove_index :fine_cancel_trackers, :school_id
      remove_index :additional_report_pdfs, :school_id
      remove_index :user_groups, :school_id
      remove_index :user_groups_users, :school_id
      remove_index :advance_fee_categories, :school_id
      remove_index :advance_fee_category_batches, :school_id
      remove_index :advance_fee_category_collections, :school_id
      remove_index :advance_fee_wallets, :school_id
      remove_index :advance_fee_collections, :school_id
      remove_index :advance_fee_deductions, :school_id
      remove_index :cancelled_advance_fee_transactions, :school_id
      remove_index :marked_attendance_records, :school_id
      remove_index :attendance_settings, :school_id
      remove_index :leave_auto_credit_records, :school_id
      remove_index :course_transcript_settings, :school_id
      
      remove_column :employee_positions, :school_id
      remove_column :employee_leaves, :school_id
      remove_column :apply_leaves, :school_id
      remove_column :employee_leave_types, :school_id
      remove_column :employee_bank_details, :school_id
      remove_column :employee_salary_structures, :school_id
      remove_column :employee_departments, :school_id
      remove_column :employee_categories, :school_id
      remove_column :individual_payslip_categories, :school_id
      remove_column :monthly_payslips, :school_id
      remove_column :employee_department_events, :school_id
      remove_column :bank_fields, :school_id
      remove_column :employees_subjects, :school_id
      remove_column :employee_attendances, :school_id
      remove_column :employee_additional_details, :school_id
      remove_column :student_previous_subject_marks, :school_id
      remove_column :exam_groups, :school_id
      remove_column :archived_exam_scores, :school_id
      remove_column :courses, :school_id
      remove_column :archived_guardians, :school_id
      remove_column :student_categories, :school_id
      remove_column :news_comments, :school_id
      remove_column :additional_fields, :school_id
      remove_column :subjects, :school_id
      remove_column :archived_employee_bank_details, :school_id
      remove_column :grading_levels, :school_id
      remove_column :batches, :school_id
      remove_column :student_additional_details, :school_id
      remove_column :exams, :school_id
      remove_column :weekdays, :school_id
      remove_column :electives, :school_id
      remove_column :archived_employee_salary_structures, :school_id
      remove_column :archived_employee_salary_structure_components, :school_id
      remove_column :configurations, :school_id
      remove_column :grouped_exams, :school_id
      remove_column :student_previous_datas, :school_id
      remove_column :batch_events, :school_id
      remove_column :period_entries, :school_id
      remove_column :guardians, :school_id
      remove_column :timetable_entries, :school_id
      remove_column :student_additional_fields, :school_id
      remove_column :events, :school_id
      remove_column :archived_employee_additional_details, :school_id
      remove_column :finance_transaction_triggers, :school_id
      remove_column :finance_fee_categories, :school_id
      remove_column :liabilities, :school_id
      remove_column :news, :school_id
      remove_column :news_attachments, :school_id
      remove_column :elective_groups, :school_id
      remove_column :fee_discounts, :school_id
      remove_column :finance_fee_collections, :school_id
      remove_column :fee_collection_particulars, :school_id
      remove_column :finance_fee_structure_elements, :school_id
      remove_column :finance_donations, :school_id
      remove_column :assets, :school_id
      remove_column :user_events, :school_id
      remove_column :finance_fee_particulars, :school_id
      remove_column :sms_settings, :school_id
      remove_column :class_timings, :school_id
      remove_column :fee_collection_discounts, :school_id
      remove_column :reminders, :school_id
      remove_column :reminder_attachments, :school_id
      remove_column :reminder_attachment_relations, :school_id
      remove_column :students_subjects, :school_id
      remove_column :finance_transaction_categories, :school_id
      remove_column :exam_scores, :school_id
      remove_column :finance_fees, :school_id
      remove_column :attendances, :school_id
      remove_column :employee_grades, :school_id
      remove_column :timetables, :school_id
      remove_column :subject_leaves, :school_id
      remove_column :sms_messages, :school_id
      remove_column :sms_logs, :school_id
      remove_column :batch_groups, :school_id
      remove_column :class_designations, :school_id
      remove_column :grouped_batches, :school_id
      remove_column :grouped_exam_reports, :school_id
      remove_column :previous_exam_scores, :school_id
      remove_column :ranking_levels, :school_id
      remove_column :assessment_scores, :school_id
      remove_column :cce_exam_categories, :school_id
      remove_column :cce_grades, :school_id
      remove_column :cce_grade_sets, :school_id
      remove_column :cce_reports, :school_id
      remove_column :cce_weightages, :school_id
      remove_column :descriptive_indicators, :school_id
      remove_column :fa_criterias, :school_id
      remove_column :fa_groups, :school_id
      remove_column :observation_groups, :school_id
      remove_column :observations, :school_id
      remove_column :additional_field_options, :school_id
      remove_column :batch_students, :school_id
      remove_column :student_additional_field_options, :school_id
      remove_column :subject_amounts, :school_id
      remove_column :weekday_sets_weekdays, :school_id
      remove_column :weekday_sets, :school_id
      remove_column :time_table_weekdays, :school_id
      remove_column :time_table_class_timings, :school_id
      remove_column :class_timing_sets, :school_id
      remove_column :biometric_informations, :school_id
      remove_column :user_menu_links, :school_id
      remove_column :timetable_swaps, :school_id
      remove_column :fines, :school_id
      remove_column :fine_rules, :school_id
      remove_column :fee_refunds, :school_id
      remove_column :refund_rules, :school_id
      remove_column :collection_particulars, :school_id
      remove_column :collection_discounts, :school_id
      remove_column :fee_transactions, :school_id
      remove_column :fee_collection_batches, :school_id
      remove_column :category_batches, :school_id
      remove_column :additional_report_csvs, :school_id
      remove_column :redactor_uploads, :school_id
      remove_column :allocated_classrooms, :school_id
      remove_column :buildings, :school_id
      remove_column :classrooms, :school_id
      remove_column :classroom_allocations, :school_id
      remove_column :ia_calculations, :school_id
      remove_column :ia_groups, :school_id
      remove_column :ia_indicators, :school_id
      remove_column :ia_scores, :school_id
      remove_column :icse_exam_categories, :school_id
      remove_column :icse_reports, :school_id
      remove_column :icse_weightages, :school_id
      remove_column :remarks, :school_id
      remove_column :remark_parameters, :school_id
      remove_column :multi_fees_transactions, :school_id
      remove_column :particular_payments, :school_id
      remove_column :particular_discounts, :school_id
      remove_column :attendance_weekday_sets, :school_id
      remove_column :discount_particular_logs, :school_id
      remove_column :batch_class_timing_sets, :school_id
      remove_column :time_table_class_timing_sets, :school_id
      remove_column :donation_additional_details, :school_id
      remove_column :donation_additional_fields, :school_id
      remove_column :donation_additional_field_options, :school_id
      remove_column :record_groups, :school_id
      remove_column :records, :school_id
      remove_column :record_field_options, :school_id
      remove_column :record_addl_attachments, :school_id
      remove_column :record_assignments, :school_id
      remove_column :record_batch_assignments, :school_id
      remove_column :student_records, :school_id
      remove_column :cce_report_settings, :school_id
      remove_column :cce_report_setting_copies, :school_id
      remove_column :asl_scores, :school_id
      remove_column :upscale_scores, :school_id
      remove_column :cbse_co_scholastic_settings, :school_id
      remove_column :eiop_settings, :school_id
      remove_column :employee_additional_leaves, :school_id
      remove_column :leave_resets, :school_id
      remove_column :leave_reset_logs, :school_id
      remove_column :payslip_settings, :school_id
      remove_column :employee_payslips, :school_id
      remove_column :employee_lops, :school_id
      remove_column :employee_overtimes, :school_id
      remove_column :employee_payslip_categories, :school_id
      remove_column :employee_salary_structure_components, :school_id
      remove_column :formula_and_conditions, :school_id
      remove_column :hr_formulas, :school_id
      remove_column :payroll_group_revisions, :school_id
      remove_column :payroll_groups_payroll_categories, :school_id
      remove_column :payslips_date_ranges, :school_id
      remove_column :salary_working_days, :school_id
      remove_column :hr_seed_errors_logs, :school_id
      remove_column :payslip_additional_leaves, :school_id
      remove_column :hr_reports, :school_id
      remove_column :icse_report_settings, :school_id
      remove_column :icse_report_setting_copies, :school_id
      remove_column :report_settings, :school_id
      remove_column :exam_group_fa_statuses, :school_id
      remove_column :student_coscholastic_remarks, :school_id
      remove_column :student_coscholastic_remark_copies, :school_id
      remove_column :observation_remarks, :school_id
      remove_column :student_attachments, :school_id
      remove_column :student_attachment_categories, :school_id
      remove_column :student_attachment_records, :school_id
      remove_column :lop_prorated_formulas, :school_id
      remove_column :payroll_revisions, :school_id
      remove_column :feature_access_settings, :school_id
      remove_column :message_threads, :school_id
      remove_column :messages, :school_id
      remove_column :message_recipients, :school_id
      remove_column :message_attachments, :school_id
      remove_column :message_settings, :school_id
      remove_column :notifications, :school_id
      remove_column :notification_recipients, :school_id
      remove_column :leave_groups, :school_id
      remove_column :leave_group_leave_types, :school_id
      remove_column :leave_group_employees, :school_id
      remove_column :academic_years, :school_id
      remove_column :assessment_plans, :school_id
      remove_column :assessment_terms, :school_id
      remove_column :assessment_groups, :school_id
      remove_column :assessment_schedules, :school_id
      remove_column :subject_assessments, :school_id
      remove_column :assessment_activities, :school_id
      remove_column :assessment_activity_profiles, :school_id
      remove_column :grades, :school_id
      remove_column :grade_sets, :school_id
      remove_column :assessment_attribute_profiles, :school_id
      remove_column :assessment_attributes, :school_id
      remove_column :assessment_plans_courses, :school_id
      remove_column :assessment_group_batches, :school_id
      remove_column :activity_assessments, :school_id
      remove_column :attribute_assessments, :school_id
      remove_column :assessment_marks, :school_id
      remove_column :assessment_report_settings, :school_id
      remove_column :derived_assessment_group_settings, :school_id
      remove_column :converted_assessment_marks, :school_id
      remove_column :individual_reports, :school_id
      remove_column :generated_reports, :school_id
      remove_column :generated_report_batches, :school_id
      remove_column :derived_assessment_groups_associations, :school_id
      remove_column :message_attachments_assocs, :school_id
      remove_column :assessment_report_setting_copies, :school_id
      remove_column :subject_attribute_assessments, :school_id
      remove_column :override_assessment_marks, :school_id
      remove_column :collectible_tax_slabs, :school_id
      remove_column :tax_assignments, :school_id
      remove_column :tax_collections, :school_id
      remove_column :tax_payments, :school_id
      remove_column :tax_slabs, :school_id
      remove_column :finance_transaction_fines, :school_id
      remove_column :multi_fee_discounts, :school_id
      remove_column :multi_transaction_fines, :school_id
      remove_column :custom_translations, :school_id
      remove_column :assessment_plan_imports, :school_id
      remove_column :job_resource_locators, :school_id
      remove_column :assessment_score_imports, :school_id
      remove_column :course_subjects, :school_id
      remove_column :subject_groups, :school_id
      remove_column :course_elective_groups, :school_id
      remove_column :subject_skill_sets, :school_id
      remove_column :subject_skills, :school_id
      remove_column :skill_assessments, :school_id
      remove_column :batch_subject_groups, :school_id
      remove_column :assessment_dates, :school_id
      remove_column :gradebook_attendances, :school_id
      remove_column :fee_accounts, :school_id
      remove_column :fee_receipt_templates, :school_id
      remove_column :finance_category_accounts, :school_id
      remove_column :finance_category_receipt_templates, :school_id
      remove_column :finance_category_receipt_sets, :school_id
      remove_column :subject_imports, :school_id
      remove_column :individual_report_pdfs, :school_id
      remove_column :gradebook_record_groups, :school_id
      remove_column :gradebook_records, :school_id
      remove_column :leave_years, :school_id
      remove_column :leave_credits, :school_id
      remove_column :leave_credit_logs, :school_id
      remove_column :attendance_labels, :school_id
      remove_column :fine_cancel_trackers, :school_id
      remove_column :additional_report_pdfs, :school_id
      remove_column :user_groups, :school_id
      remove_column :user_groups_users, :school_id
      remove_column :advance_fee_categories, :school_id
      remove_column :advance_fee_category_batches, :school_id
      remove_column :advance_fee_category_collections, :school_id
      remove_column :advance_fee_wallets, :school_id
      remove_column :advance_fee_collections, :school_id
      remove_column :advance_fee_deductions, :school_id
      remove_column :cancelled_advance_fee_transactions, :school_id
      remove_column :marked_attendance_records, :school_id
      remove_column :attendance_settings, :school_id
      remove_column :leave_auto_credit_records, :school_id
      remove_column :course_transcript_settings, :school_id
    end
end