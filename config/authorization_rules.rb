authorization do

  #open -   privileges
  role :open do
    has_permission_on [:calendar],
                      :to => [
                          :index
                      ]
    #    has_permission_on [:reminder],
    #      :to => [
    #      :index,
    #      :sent_reminder
    #    ]
    has_permission_on [:messages],
                      :to => [
                          :index,
                          :update_message_scroll,
                          :create,
                          :create_message,
                          :update_thread,
                          :apply_actions,
                          :update_conversation,
                          :switch_tabs,
                          :create_broadcast,
                          :to_employees,
                          :to_students,
                          :to_parents,
                          :update_recipient_list,
                          :update_recipient_list1,
                          :update_recipient_list2,
                          :recipient_search_autocomplete,
                          :check_parent,
                          :render_messages,
                          :new,
                          :update_recipients,
                          :show_message_box
                      ]
    has_permission_on [:notifications],
                      :to => [
                          :index,
                          :apply_filter,
                          :mark_notification_read,
                          :show_notification_box
                      ]
  end

  #custom - privileges
  role :examination_control do
    includes :archived_exam_reports
    has_permission_on [:exam],
                      :to => [
                          :index,
                          :previous_batch_exams,
                          :course_wise_exams,
                          :create_course_wise_exam_group,
                          :update_exam_form_with_multibatch,
                          :update_batch_in_course_wise_exams,
                          :list_inactive_batches,
                          :list_inactive_exam_groups,
                          :previous_exam_marks,
                          :edit_previous_marks,
                          :update_previous_marks,
                          #      :create_exam,
                          :list_exam_groups,
                          :update_batch,
                          :create_examtype,
                          :create,
                          :create_grading,
                          :delete,
                          :delete_examtype,
                          :delete_grading,
                          :edit,
                          :edit_examtype,
                          :edit_grading,
                          :grading_form_edit,
                          :rename_grading,
                          :update_subjects_dropdown,
                          :publish,
                          :grouping,
                          :update_exam_form,
                          :exam_wise_report,
                          :list_exam_types,
                          :generated_report,
                          :graph_for_generated_report,
                          :generated_report_pdf,
                          :consolidated_exam_report,
                          :consolidated_exam_report_pdf,
                          :subject_wise_report,
                          :subject_rank,
                          :course_rank,
                          :batch_groups,
                          :student_course_rank,
                          :student_course_rank_pdf,
                          :student_school_rank,
                          :student_school_rank_pdf,
                          :attendance_rank,
                          :student_attendance_rank,
                          :student_attendance_rank_pdf,
                          :generate_reports,
                          :generate_previous_reports,
                          :select_inactive_batches,
                          :settings,
                          :report_center,
                          :gpa_cwa_reports,
                          :list_batch_groups,
                          :ranking_level_report,
                          :student_ranking_level_report,
                          :student_ranking_level_report_pdf,
                          :transcript,
                          :student_transcript,
                          :student_transcript_pdf,
                          :combined_report,
                          :load_levels,
                          :student_combined_report,
                          :student_combined_report_pdf,
                          :load_batch_students,
                          :select_mode,
                          :select_batch_group,
                          :select_type,
                          :select_report_type,
                          :batch_rank,
                          :student_batch_rank,
                          :student_batch_rank_pdf,
                          :student_subject_rank,
                          :student_subject_rank_pdf,
                          :list_subjects,
                          :list_batch_subjects,
                          :generated_report2,
                          :generated_report2_pdf,
                          :grouped_exam_report,
                          :final_report_type,
                          :generated_report4,
                          :generated_report4_pdf,
                          :combined_grouped_exam_report_pdf,
                          :student_wise_generated_report,
                          :report_settings,
                          :get_normal_report_header_info,
                          :get_report_signature_info,
                          :preview,
                          :students_sorting,
                          :save_sorting_method
                      ]

    has_permission_on [:exam],
                      :to => [
                          :gpa_settings,
                          :transcript_settings,
                          :save_transcript_setting,
                          :cgpa_average_example,
                          :cgpa_credit_hours_example
                      ] do
      if_attribute :gpa_enabled? => is { true }
    end

    has_permission_on [:scheduled_jobs],
                      :to => [
                          :index
                      ]
    has_permission_on [:exam_groups],
                      :to => [
                          :index,
                          :new,
                          :create,
                          :update,
                          :destroy,
                          :show,
                          :edit,
                          :set_exam_minimum_marks,
                          :set_exam_maximum_marks,
                          :set_exam_weightage,
                          :set_exam_group_name,
                          :subject_list,
                          :fa_group_result_publish,
                          :sent_resend_fa_group_publish_sms
                      ]
    has_permission_on [:exams],
                      :to => [
                          :index,
                          :show,
                          :new,
                          :create,
                          :add_new_exams,
                          :edit,
                          :update,
                          :destroy,
                          :save_scores,
                          :query_data
                      ]
    #    has_permission_on [:additional_exam],
    #      :to => [
    #      :index,
    #      :update_exam_form,
    #      :publish,
    #      :create_additional_exam,
    #      :update_batch
    #    ]

    #    has_permission_on [:additional_exam_groups],
    #      :to => [
    #      :index,
    #      :new,
    #      :create,
    #      :edit,
    #      :update,
    #      :destroy,
    #      :show,
    #      :initial_queries,
    #      :set_additional_exam_minimum_marks,
    #      :set_additional_exam_maximum_marks,
    #      :set_additional_exam_weightage,
    #      :set_additional_exam_group_name
    #    ]
    #    has_permission_on [:additional_exams],
    #      :to => [
    #      :index,
    #      :show,
    #      :new,
    #      :create,
    #      :edit,
    #      :update,
    #      :destroy,
    #      :save_additional_scores,
    #      :query_data
    #    ]
    has_permission_on [:grading_levels],
                      :to => [
                          :index,
                          :show,
                          :edit,
                          :update,
                          :new,
                          :create,
                          :destroy

                      ]
    has_permission_on [:ranking_levels],
                      :to => [
                          :index,
                          :load_ranking_levels,
                          :create_ranking_level,
                          :edit_ranking_level,
                          :update_ranking_level,
                          :delete_ranking_level,
                          :ranking_level_cancel,
                          :change_priority
                      ]
    has_permission_on [:class_designations],
                      :to => [
                          :index,
                          :load_class_designations,
                          :create_class_designation,
                          :edit_class_designation,
                          :update_class_designation,
                          :delete_class_designation
                      ]
    has_permission_on [:descriptive_indicators],
                      :to => [
                          :index,
                          :show,
                          :new,
                          :create,
                          :edit,
                          :update,
                          :destroy,
                          :reorder,
                          :destroy_indicator,
                          :show_in_report
                      ], :join_by => :and do
      if_attribute :assess_truth => is { user.cce_enabled? }
    end
    has_permission_on [:fa_criterias],
                      :to => [
                          :index,
                          :show
                      ], :join_by => :and do
      if_attribute :assess_truth => is { user.cce_enabled? }
    end
    has_permission_on [:fa_groups],
                      :to => [
                          :index,
                          :new,
                          :create,
                          :edit,
                          :update,
                          :show,
                          :destroy,
                          :assign_fa_groups,
                          :select_subjects,
                          :select_fa_groups,
                          :update_subject_fa_groups,
                          :new_fa_criteria,
                          :create_fa_criteria,
                          :edit_fa_criteria,
                          :update_fa_criteria,
                          :destroy_fa_criteria,
                          :reorder,
                          :edit_criteria_formula,
                          :update_criteria_formula,
                          :formula_examples

                      ], :join_by => :and do
      if_attribute :assess_truth => is { user.cce_enabled? }
    end
    has_permission_on [:observation_groups],
                      :to => [
                          :index,
                          :new,
                          :create,
                          :edit,
                          :edit_observation,
                          :update,
                          :show,
                          :destroy,
                          :new_observation,
                          :create_observation,
                          :edit_osbervation,
                          :update_observation,
                          :destroy_observation,
                          :assign_courses,
                          :select_observation_groups,
                          :update_course_obs_groups,
                          :reorder,
                          :reorder_ob_groups
                      ], :join_by => :and do
      if_attribute :assess_truth => is { user.cce_enabled? }
    end
    has_permission_on [:observation_remarks],
                      :to => [
                          :new,
                          :create,
                          :edit,
                          :update,
                          :destroy,
                          :co_scholastic_remark_settings,
                          :get_di_info,
                      ], :join_by => :and do
      if_attribute :assess_truth => is { user.cce_enabled? }
    end
    has_permission_on [:observations],
                      :to => [
                          :show
                      ], :join_by => :and do
      if_attribute :assess_truth => is { user.cce_enabled? }
    end
    has_permission_on [:assessment_scores],
                      :to => [
                          :fa_scores,
                          :observation_groups,
                          :observation_scores,
                          :get_grade,
                          :search_batch_students,
                          :get_fa_groups,
                          :scores_form
                      ], :join_by => :and do
      if_attribute :assess_truth => is { user.cce_enabled? }
    end
    has_permission_on [:asl_scores],
                      :to => [
                          :show,
                          :save_scores
                      ], :join_by => :and do
      if_attribute :assess_truth => is { user.cce_enabled? }
    end
    has_permission_on [:cce_exam_categories],
                      :to => [
                          :index,
                          :new,
                          :create,
                          :show,
                          :edit,
                          :update,
                          :destroy
                      ], :join_by => :and do
      if_attribute :assess_truth => is { user.cce_enabled? }
    end
    has_permission_on [:cce_grade_sets],
                      :to => [
                          :index,
                          :new,
                          :create,
                          :edit,
                          :update,
                          :destroy,
                          :show,
                          :index,
                          :new_grade,
                          :create_grade,
                          :edit_grade,
                          :update_grade,
                          :destroy_grade
                      ], :join_by => :and do
      if_attribute :assess_truth => is { user.cce_enabled? }
    end
    has_permission_on [:cce_reports],
                      :to => [
                          :index,
                          :create_reports,
                          :student_wise_report,
                          :generate_student_wise_report,
                          :student_report_pdf,
                          :student_transcript,
                          :student_report,
                          :consolidated_report,
                          :detailed_fa_report,
                          :detailed_fa_batches,
                          :detailed_fa_list_subjects,
                          :detailed_fa_list_fa_groups,
                          :generated_detailed_fa_report,
                          :generated_detailed_fa_report_csv,
                          :list_batches,
                          :update_assessment_groups,
                          :generated_report,
                          :generated_report_csv,
                          :generated_report_pdf,
                          :subject_wise_report,
                          :subject_wise_batches,
                          :list_subjects,
                          :subject_wise_generated_report,
                          :subject_wise_generated_report_csv,
                          :subject_wise_generated_report_pdf,
                          :list_exam_groups,
                          :list_asl_groups,
                          :asl_report_csv,
                          :set_assessment_group,
                          :full_report_pdf,
                          :cbse_report,
                          :asl_report,
                          :generate_asl_report,
                          :upscale_report,
                          :cbse_scholastic_report,
                          :cbse_co_scholastic_report,
                          :generate_cbse_scholastic_report,
                          :list_observation_groups,
                          :generate_cbse_co_scholastic_report,
                          :generate_cbse_scholastic_report_csv,
                          :cce_full_exam_report,
                          :generate_cbse_co_scholastic_report_csv,
                          :batch_student_report,
                          :new_batch_wise_student_report,
                          :generate_batch_student_report,
                          :batch_wise_student_report_download,
                          :get_batches,
                          :get_students_list,
                          :previous_batch_exam_reports,
                          :list_previous_batches,
                          :generate_previous_batch_exam_reports,
                          :student_fa_report_pdf
                      ], :join_by => :and do
      if_attribute :assess_truth => is { user.cce_enabled? }
    end

    has_permission_on [:cce_settings],
                      :to => [
                          :index,
                          :basic,
                          :scholastic,
                          :co_scholastic
                      ], :join_by => :and do
      if_attribute :assess_truth => is { user.cce_enabled? }
    end
    has_permission_on [:cce_settings],
                      :to => [
                          :fa_settings,
                          :fa_total_example,
                          :fa_average_example
                      ], :join_by => :and do
      if_attribute :assess_truth => is { user.cce_enabled? }
    end
    has_permission_on [:cce_report_settings],
                      :to => [
                          :settings,
                          :normal_report_settings,
                          :update_record_lists,
                          :get_report_header_info,
                          :get_additional_fields,
                          :get_normal_report_header_info,
                          :get_report_grading_levels_info,
                          :get_report_signature_info,
                          :unlink,
                          :preview,
                          :normal_preview,
                          :upscale_settings,
                          :upscale_scores,
                          :get_course_batch_selector,
                          :get_batches_list,
                          :get_inactive_batches_list,
                          :cancel,
                          :save_upscale_scores,
                          :cbse_co_scholastic_settings,
                          :get_observations,
                          :save_cbse_co_scholastic_settings,
                          :manage_criteria
                      ], :join_by => :and do
      if_attribute :assess_truth => is { user.cce_enabled? }
    end
    has_permission_on [:cce_weightages],
                      :to => [
                          :index,
                          :new,
                          :create,
                          :show,
                          :edit,
                          :update,
                          :destroy,
                          :assign_courses,
                          :assign_weightages,
                          :select_weightages,
                          :update_course_weightages
                      ], :join_by => :and do
      if_attribute :assess_truth => is { user.cce_enabled? }
    end
    has_permission_on [:course_exam_groups],
                      :to => [
                          :index,
                          :show,
                          :create,
                          :new,
                          :edit,
                          :new_batches,
                          :add_exams,
                          :list_tabs,
                          :list_exam_batches,
                          :list_batches,
                          :update,
                          :list_exam_groups,
                          :update_course_exam_group,
                          :add_batches,
                          :update_imported_exams,
                          :batch_wise_exam_groups,
                          :common_exam_groups
                      ]
    has_permission_on [:batches], :to => [:batches_ajax]
    has_permission_on [:csv_export], :to => [:generate_csv]
    has_permission_on [:report], :to => [:csv_reports, :csv_report_download, :pdf_reports, :pdf_report_download]

    has_permission_on [:icse_settings],
                      :to => [
                          :index,
                          :icse_exam_categories,
                          :new_icse_exam_category,
                          :create_icse_exam_category,
                          :edit_icse_exam_category,
                          :update_icse_exam_category,
                          :destroy_icse_exam_category,
                          :icse_weightages,
                          :new_icse_weightage,
                          :create_icse_weightage,
                          :edit_icse_weightage,
                          :update_icse_weightage,
                          :destroy_icse_weightage,
                          :assign_icse_weightages,
                          :select_subjects,
                          :select_icse_weightages,
                          :update_subject_weightages,
                          :internal_assessment_groups,
                          :new_ia_group,
                          :create_ia_group,
                          :edit_ia_group,
                          :update_ia_group,
                          :destroy_ia_group,
                          :assign_ia_groups,
                          :ia_group_subjects,
                          :select_ia_groups,
                          :update_subject_ia_groups,
                          :ia_settings,
                          :ia_total_example,
                          :ia_average_example
                      ], :join_by => :and do
      if_attribute :assess_truth => is { user.icse_enabled? }
    end
    has_permission_on [:ia_scores],
                      :to => [
                          :ia_scores,
                          :update_ia_score
                      ], :join_by => :and do
      if_attribute :assess_truth => is { user.icse_enabled? }
    end
    has_permission_on [:icse_reports],
                      :to => [
                          :index,
                          :generate_reports,
                          :student_wise_report,
                          :generate_student_wise_report,
                          :student_report,
                          :student_report_pdf,
                          :student_transcript,
                          :subject_wise_report,
                          :list_batches,
                          :list_subjects,
                          :list_exam_groups,
                          :set_assessment_group,
                          :subject_wise_generated_report,
                          :internal_and_external_mark_pdf,
                          :detailed_internal_and_external_mark_pdf,
                          :internal_and_external_mark_csv,
                          :detailed_internal_and_external_mark_csv,
                          :consolidated_report,
                          :consolidated_generated_report,
                          :consolidated_report_csv,
                          :student_report_csv,
                          :batches_ajax,
                          :previous_batch_exam_reports,
                          :list_previous_batches,
                          :generate_previous_batch_exam_reports
                      ], :join_by => :and do
      if_attribute :assess_truth => is { user.icse_enabled? }
    end
    has_permission_on [:icse_report_settings],
                      :to => [
                          :settings,
                          :get_report_header_info,
                          :get_report_signature_info,
                          :get_report_grading_levels_info,
                          :preview
                      ], :join_by => :and do
      if_attribute :assess_truth => is { user.icse_enabled? }
    end

  end

  role :enter_results do
    includes :archived_exam_reports
    has_permission_on [:exam],
                      :to => [
                          :index,
                          :previous_batch_exams,
                          :list_inactive_batches,
                          :list_inactive_exam_groups,
                          :previous_exam_marks,
                          :edit_previous_marks,
                          :update_previous_marks,
                          #      :create_exam,
                          :update_batch,
                          :exam_wise_report,
                          :list_exam_types,
                          :generated_report,
                          :update_assessment_groups,
                          :graph_for_generated_report,
                          :generated_report_pdf,
                          :consolidated_exam_report,
                          :consolidated_exam_report_pdf,
                          :subject_wise_report,
                          :subject_rank,
                          :course_rank,
                          :batch_groups,
                          :student_course_rank,
                          :student_course_rank_pdf,
                          :student_school_rank,
                          :student_school_rank_pdf,
                          :attendance_rank,
                          :student_attendance_rank,
                          :student_attendance_rank_pdf,
                          :report_center,
                          :gpa_cwa_reports,
                          :list_batch_groups,
                          :ranking_level_report,
                          :student_ranking_level_report,
                          :student_ranking_level_report_pdf,
                          :transcript,
                          :student_transcript,
                          :student_transcript_pdf,
                          :combined_report,
                          :load_levels,
                          :student_combined_report,
                          :student_combined_report_pdf,
                          :load_batch_students,
                          :select_mode,
                          :select_batch_group,
                          :select_type,
                          :select_report_type,
                          :batch_rank,
                          :student_batch_rank,
                          :student_batch_rank_pdf,
                          :student_subject_rank,
                          :student_subject_rank_pdf,
                          :list_subjects,
                          :list_batch_subjects,
                          :generated_report2,
                          :generated_report2_pdf,
                          :grouped_exam_report,
                          :final_report_type,
                          :generated_report4,
                          :generated_report4_pdf,
                          :combined_grouped_exam_report_pdf,
                          :student_wise_generated_report
                      ]
    has_permission_on [:cce_report_settings],
                      :to => [
                          :upscale_scores,
                          :get_course_batch_selector,
                          :get_batches_list,
                          :get_inactive_batches_list,
                          :cancel,
                          :save_upscale_scores,
                      ], :join_by => :and do
      if_attribute :assess_truth => is { user.cce_enabled? }
    end
    has_permission_on [:exam_groups],
                      :to => [
                          :index,
                          :show,
                          :subject_list
                      ]
    has_permission_on [:exams],
                      :to => [
                          :index,
                          :show,
                          :save_scores
                      ]
    #    has_permission_on [:additional_exam],
    #      :to =>[
    #      :create_additional_exam,
    #      :update_batch,
    #      :publish
    #    ]
    #    has_permission_on [:additional_exam_groups],
    #      :to =>[
    #      :index,
    #      :show,
    #      :set_additional_exam_minimum_marks,
    #      :set_additional_exam_maximum_marks,
    #      :set_additional_exam_weightage,
    #      :set_additional_exam_group_name
    #    ]
    #    has_permission_on [:additional_exams],
    #      :to => [
    #      :index,
    #      :show,
    #      :save_additional_scores
    #    ]
    has_permission_on [:assessment_scores],
                      :to => [
                          :fa_scores,
                          :observation_groups,
                          :observation_scores,
                          :get_grade,
                          :search_batch_students,
                          :get_fa_groups,
                          :scores_form
                      ], :join_by => :and do
      if_attribute :assess_truth => is { user.cce_enabled? }
    end
    has_permission_on [:asl_scores],
                      :to => [
                          :show,
                          :save_scores
                      ], :join_by => :and do
      if_attribute :assess_truth => is { user.cce_enabled? }
    end

    has_permission_on [:cce_reports],
                      :to => [
                          :index,
                          :student_wise_report,
                          :generate_student_wise_report,
                          :student_report_pdf,
                          :student_transcript,
                          :student_report,
                          :consolidated_report,
                          :detailed_fa_report,
                          :detailed_fa_batches,
                          :detailed_fa_list_subjects,
                          :detailed_fa_list_fa_groups,
                          :generated_detailed_fa_report,
                          :generated_detailed_fa_report_csv,
                          :list_batches,
                          :update_assessment_groups,
                          :generated_report,
                          :generated_report_csv,
                          :generated_report_pdf,
                          :subject_wise_report,
                          :subject_wise_batches,
                          :list_subjects,
                          :subject_wise_generated_report,
                          :subject_wise_generated_report_csv,
                          :subject_wise_generated_report_pdf,
                          :list_exam_groups,
                          :list_asl_groups,
                          :asl_report_csv,
                          :generate_asl_report,
                          :set_assessment_group,
                          :full_report_pdf,
                          :cbse_report,
                          :asl_report,
                          :upscale_report,
                          :cbse_scholastic_report,
                          :cbse_co_scholastic_report,
                          :generate_cbse_scholastic_report,
                          :list_observation_groups,
                          :generate_cbse_co_scholastic_report,
                          :generate_cbse_scholastic_report_csv,
                          :cce_full_exam_report,
                          :generate_cbse_co_scholastic_report_csv,
                          :previous_batch_exam_reports,
                          :list_previous_batches,
                          :generate_previous_batch_exam_reports,
                          :batch_student_report,
                          :batch_wise_student_report_download,
                          :student_fa_report_pdf
                      ], :join_by => :and do
      if_attribute :assess_truth => is { user.cce_enabled? }
    end

    has_permission_on [:ia_scores],
                      :to => [
                          :ia_scores,
                          :update_ia_score
                      ], :join_by => :and do
      if_attribute :assess_truth => is { user.icse_enabled? }
    end
    has_permission_on [:icse_reports],
                      :to => [
                          :index,
                          :student_wise_report,
                          :generate_student_wise_report,
                          :student_report,
                          :student_report_pdf,
                          :student_transcript,
                          :subject_wise_report,
                          :list_batches,
                          :list_subjects,
                          :list_exam_groups,
                          :subject_wise_generated_report,
                          :internal_and_external_mark_pdf,
                          :detailed_internal_and_external_mark_pdf,
                          :internal_and_external_mark_csv,
                          :detailed_internal_and_external_mark_csv,
                          :consolidated_report,
                          :consolidated_generated_report,
                          :consolidated_report_csv,
                          :student_report_csv,
                          :previous_batch_exam_reports,
                          :list_previous_batches,
                          :generate_previous_batch_exam_reports
                      ], :join_by => :and do
      if_attribute :assess_truth => is { user.icse_enabled? }
    end
    has_permission_on [:scheduled_jobs],
                      :to => [
                          :index
                      ]
    has_permission_on [:course_exam_groups],
                      :to => [
                          :index,
                          :show,
                          :list_tabs,
                          :list_exam_batches,
                          :list_batches,
                          :list_exam_groups,
                          :batch_wise_exam_groups,
                          :common_exam_groups
                      ]

  end

  role :view_results do
    includes :archived_exam_reports
    has_permission_on [:student], :to => [:reports]
    has_permission_on [:exam], :to => [:index,
                                       :exam_wise_report,
                                       :list_exam_types,
                                       :update_assessment_groups,
                                       :generated_report,
                                       :graph_for_generated_report,
                                       :generated_report_pdf,
                                       :consolidated_exam_report,
                                       :consolidated_exam_report_pdf,
                                       :subject_wise_report,
                                       :subject_rank,
                                       :course_rank,
                                       :batch_groups,
                                       :student_course_rank,
                                       :student_course_rank_pdf,
                                       :student_school_rank,
                                       :student_school_rank_pdf,
                                       :attendance_rank,
                                       :student_attendance_rank,
                                       :student_attendance_rank_pdf,
                                       :report_center,
                                       :gpa_cwa_reports,
                                       :list_batch_groups,
                                       :ranking_level_report,
                                       :student_ranking_level_report,
                                       :student_ranking_level_report_pdf,
                                       :transcript,
                                       :student_transcript,
                                       :student_transcript_pdf,
                                       :combined_report,
                                       :load_levels,
                                       :student_combined_report,
                                       :student_combined_report_pdf,
                                       :load_batch_students,
                                       :select_mode,
                                       :select_batch_group,
                                       :select_type,
                                       :select_report_type,
                                       :batch_rank,
                                       :student_batch_rank,
                                       :student_batch_rank_pdf,
                                       :student_subject_rank,
                                       :student_subject_rank_pdf,
                                       :list_subjects,
                                       :list_batch_subjects,
                                       :generated_report2,
                                       :generated_report2_pdf,
                                       :grouped_exam_report,
                                       :final_report_type,
                                       :generated_report4,
                                       :generated_report4_pdf,
                                       :combined_grouped_exam_report_pdf,
                                       :student_wise_generated_report
                             ]
    has_permission_on [:cce_reports],
                      :to => [
                          :index,
                          :student_wise_report,
                          :generate_student_wise_report,
                          :student_report_pdf,
                          :student_transcript,
                          :student_report,
                          :consolidated_report,
                          :detailed_fa_report,
                          :detailed_fa_batches,
                          :detailed_fa_list_subjects,
                          :detailed_fa_list_fa_groups,
                          :generated_detailed_fa_report,
                          :generated_detailed_fa_report_csv,
                          :list_batches,
                          :update_assessment_groups,
                          :generated_report,
                          :generated_report_csv,
                          :generated_report_pdf,
                          :subject_wise_report,
                          :subject_wise_batches,
                          :list_subjects,
                          :subject_wise_generated_report,
                          :subject_wise_generated_report_csv,
                          :subject_wise_generated_report_pdf,
                          :list_exam_groups,
                          :list_asl_groups,
                          :asl_report_csv,
                          :generate_asl_report,
                          :set_assessment_group,
                          :full_report_pdf,
                          :cbse_report,
                          :asl_report,
                          :upscale_report,
                          :cbse_scholastic_report,
                          :cbse_co_scholastic_report,
                          :generate_cbse_scholastic_report,
                          :list_observation_groups,
                          :generate_cbse_co_scholastic_report,
                          :generate_cbse_scholastic_report_csv,
                          :cce_full_exam_report,
                          :generate_cbse_co_scholastic_report_csv,
                          :previous_batch_exam_reports,
                          :list_previous_batches,
                          :generate_previous_batch_exam_reports,
                          :batch_student_report,
                          :batch_wise_student_report_download,
                          :student_fa_report_pdf
                      ], :join_by => :and do
      if_attribute :assess_truth => is { user.cce_enabled? }
    end

    has_permission_on [:icse_reports],
                      :to => [
                          :index,
                          :student_wise_report,
                          :generate_student_wise_report,
                          :student_report,
                          :student_report_pdf,
                          :student_transcript,
                          :subject_wise_report,
                          :list_batches,
                          :list_subjects,
                          :list_exam_groups,
                          :subject_wise_generated_report,
                          :internal_and_external_mark_pdf,
                          :detailed_internal_and_external_mark_pdf,
                          :internal_and_external_mark_csv,
                          :detailed_internal_and_external_mark_csv,
                          :consolidated_report,
                          :consolidated_generated_report,
                          :consolidated_report_csv,
                          :student_report_csv,
                          :previous_batch_exam_reports,
                          :list_previous_batches,
                          :generate_previous_batch_exam_reports
                      ], :join_by => :and do
      if_attribute :assess_truth => is { user.icse_enabled? }
    end
  end

  role :admission do
    includes :manage_student_attachment
    has_permission_on [:student],
                      :to => [
                          :profile,
                          :admission1,
                          :render_batch_list,
                          :set_roll_number_prefix,
                          :admission1_2,
                          :search_ajax,
                          :admission2,
                          :admission3,
                          :previous_data,
                          :delete_previous_subject,
                          :previous_data_from_profile,
                          :previous_data_edit,
                          :previous_subject,
                          :save_previous_subject,
                          :admission4,
                          :profile,
                          :add_guardian,
                          :admission3_1,
                          :edit,
                          :fees,
                          :edit_guardian,
                          :guardians,
                          :del_guardian,
                          :list_students_by_course,
                          :show,
                          #:view_all,
                          :profile_pdf,
                          :edit,
                          :show_previous_details,
                          #:remove,
                          #:change_to_former,
                          #:delete,
                          :generate_tc_pdf,
                          :edit_admission4,
                          :fee_details,
                          :destroy,
                          :activities,
                          :update_activities,
                          #:destroy_dependencies,
                          :student_fees_preference,
                          :unlink_sibling
                      ]

    has_permission_on [:scheduled_jobs],
                      :to => [
                          :index
                      ]
    has_permission_on [:archived_student], :to => [:edit_leaving_date]
    has_permission_on [:remarks], :to => [:custom_remark_list, :list_custom_remarks]
    has_permission_on [:remarks], :to => [:remarks_history, :remarks_pdf, :remarks_csv] do
      if_attribute :is_deleted => is { false }
    end
  end

  role :students_control do
    includes :generate_tc
    includes :manage_student_attachment
    includes :manage_student_attachment_categories
    has_permission_on [:student],
                      :to => [
                          :academic_reports_pdf,
                          :academic_report,
                          :academic_report_all,
                          :profile,
                          :guardians,
                          :list_students_by_course,
                          :show,
                          :view_all,
                          :index,
                          :change_to_former,
                          :delete, :destroy,
                          :exam_report,
                          :update_student_result_for_examtype,
                          :previous_years_marks_overview,
                          :previous_years_marks_overview_pdf,
                          :remove, :reports,
                          :search_ajax,
                          :subject_wise_report,
                          :graph_for_previous_years_marks_overview,
                          :graph_for_student_annual_overview,
                          :graph_for_subject_wise_report_for_one_subject,
                          :graph_for_exam_report,
                          :graph_for_academic_report,
                          :generate_tc_pdf,
                          :generate_all_tc_pdf,
                          :advanced_search,
                          :advanced_search_pdf,
                          :edit,
                          :previous_data_edit,
                          :profile_pdf,
                          :edit_guardian,
                          :del_guardian,
                          :add_guardian,
                          :show_previous_details,
                          :list_doa_year,
                          :doa_equal_to_update,
                          :doa_less_than_update,
                          :doa_greater_than_update,
                          :list_dob_year,
                          :dob_equal_to_update,
                          :dob_less_than_update,
                          :dob_greater_than_update,
                          :list_batches,
                          :find_student,
                          :fees,
                          :fee_details,
                          :admission3_1,
                          :admission3_2,
                          :immediate_contact2,
                          :admission1_2,
                          :my_subjects,
                          :choose_elective,
                          :remove_elective,
                          :admission1,
                          :render_batch_list,
                          :set_roll_number_prefix,
                          :admission2,
                          :admission3,
                          :previous_data,
                          :previous_data_from_profile,
                          :previous_subject,
                          :save_previous_subject,
                          :delete_previous_subject,
                          :admission4,
                          :edit_admission4,
                          :activities,
                          :update_activities,
                          :destroy_dependencies,
                          :student_fees_preference,
                          :unlink_sibling
                      ]

    has_permission_on [:scheduled_jobs],
                      :to => [
                          :index
                      ]
    has_permission_on [:finance], :to => [:refund_student_view, :refund_student_view_pdf]
    has_permission_on [:archived_student],
                      :to => [
                          :profile,
                          :reports,
                          :guardians,
                          :delete,
                          :destroy,
                          :generate_tc_pdf,
                          :consolidated_exam_report,
                          :consolidated_exam_report_pdf,
                          :academic_report,
                          :student_report,
                          :generated_report,
                          :generated_report_pdf,
                          :generated_report3,
                          :previous_years_marks_overview,
                          :previous_years_marks_overview_pdf,
                          :generated_report4,
                          :generated_report4_pdf,
                          :graph_for_generated_report,
                          :graph_for_generated_report3,
                          :graph_for_previous_years_marks_overview,
                          :edit_leaving_date,
                          :revert_archived_student,
                          :fees
                      ]             
    has_permission_on [:advance_payment_fees], :to => [
                        :advance_fee_students,
                        :batch_wise_monthly_expense_report
                      ]
    has_permission_on [:exam],
                      :to => [
                          :generated_report,
                          :generated_report_pdf,
                          :consolidated_exam_report,
                          :consolidated_exam_report_pdf,
                          :generated_report3,
                          :generated_report3_pdf,
                          :generated_report4,
                          :generated_report4_pdf,
                          :combined_grouped_exam_report_pdf,
                          :graph_for_generated_report,
                          :graph_for_generated_report3,
                          :previous_years_marks_overview,
                          :previous_years_marks_overview_pdf,
                          :academic_report,
                          :graph_for_previous_years_marks_overview,
                          :student_wise_generated_report,
                          :student_transcript,
                          :student_transcript_pdf
                      ]
    has_permission_on [:student_attendance],
                      :to => [
                          :student,
                          :leaves_report,
                          :month,
                          :student_report
                      ]
    has_permission_on [:cce_reports],
                      :to => [
                          :student_transcript,
                          :student_report_pdf,
                          :cce_full_exam_report,
                          :student_fa_report_pdf
                      ] do
      if_attribute :cce_enabled? => is { true }
    end
    has_permission_on [:csv_export], :to => [:generate_csv]
    has_permission_on [:report], :to => [:csv_reports, :csv_report_download, :pdf_reports, :pdf_report_download]
    has_permission_on [:remarks], :to => [:add_employee_custom_remarks, :list_batches, :list_student_with_remark_subject, :employee_custom_remark_update, :employee_list_custom_remarks, :list_specific_batches, :list_students, :list_student_custom_remarks, :add_custom_remarks, :create_custom_remarks, :edit_custom_remarks, :update_custom_remarks, :destroy_custom_remarks, :custom_remark_list, :remarks_history, :list_custom_remarks, :index, :remarks_pdf, :remarks_csv]
    has_permission_on [:icse_reports],
                      :to => [
                          :student_report_pdf,
                          :student_transcript,
                          :student_report_csv,
                      ] do
      if_attribute :icse_enabled? => is { true }
    end
    has_permission_on [:student_records],
                      :to => [
                          :individual_student_records
                      ]
  end

  role :student_view do
    includes :view_tc
    includes :view_student_attachment
    has_permission_on [:student],
                      :to => [
                          :academic_reports_pdf,
                          :academic_report,
                          :academic_report_all,
                          :profile,
                          :guardians,
                          :list_students_by_course,
                          :show,
                          :view_all,
                          :index,
                          :exam_report,
                          :previous_years_marks_overview,
                          :previous_years_marks_overview_pdf,
                          :search_ajax,
                          :subject_wise_report,
                          :graph_for_previous_years_marks_overview,
                          :graph_for_student_annual_overview,
                          :graph_for_subject_wise_report_for_one_subject,
                          :graph_for_exam_report,
                          :graph_for_academic_report,
                          :advanced_search,
                          :advanced_search_pdf,
                          :profile_pdf,
                          :show_previous_details,
                          :list_doa_year,
                          :doa_equal_to_update,
                          :doa_less_than_update,
                          :doa_greater_than_update,
                          :list_dob_year,
                          :dob_equal_to_update,
                          :dob_less_than_update,
                          :dob_greater_than_update,
                          :list_batches,
                          :find_student,
                          :fees,
                          :fee_details,
                          :admission3_2,
                          :immediate_contact2,
                          :generate_tc_pdf,
                          :generate_all_tc_pdf,
                          :my_subjects,
                          :reports,
                          :activities,
                          :update_activities,
                          :student_fees_preference
                      ]
    has_permission_on [:remarks], :to => [:custom_remark_list, :remarks_history, :list_custom_remarks, :remarks_pdf, :remarks_csv]
    has_permission_on [:finance], :to => [:refund_student_view, :refund_student_view_pdf]
    has_permission_on [:archived_student],
                      :to => [
                          :profile,
                          :reports,
                          :guardians,
                          :generate_tc_pdf,
                          :consolidated_exam_report,
                          :consolidated_exam_report_pdf,
                          :academic_report,
                          :student_report,
                          :generated_report,
                          :generated_report_pdf,
                          :generated_report3,
                          :previous_years_marks_overview,
                          :previous_years_marks_overview_pdf,
                          :generated_report4,
                          :generated_report4_pdf,
                          :graph_for_generated_report,
                          :graph_for_generated_report3,
                          :graph_for_previous_years_marks_overview,
                          :fees
                      ]
  has_permission_on [:advance_payment_fees], :to => [
                        :advance_fee_students
                      ]
    has_permission_on [:exam],
                      :to => [
                          :generated_report,
                          :generated_report_pdf,
                          :student_wise_generated_report,
                          :consolidated_exam_report,
                          :consolidated_exam_report_pdf,
                          :generated_report3,
                          :generated_report3_pdf,
                          :generated_report4,
                          :generated_report4_pdf,
                          :combined_grouped_exam_report_pdf,
                          :graph_for_generated_report,
                          :graph_for_generated_report3,
                          :previous_years_marks_overview,
                          :previous_years_marks_overview_pdf,
                          :academic_report,
                          :graph_for_previous_years_marks_overview,
                          :student_transcript,
                          :student_transcript_pdf
                      ]
    has_permission_on [:student_attendance],
                      :to => [
                          :student,
                          :leaves_report,
                          :month,
                          :student_report
                      ]
    has_permission_on [:cce_reports], :to => [
                                        :student_transcript,
                                        :student_report_pdf,
                                        :cce_full_exam_report,
                                        :student_fa_report_pdf
                                    ] do
      if_attribute :cce_enabled? => is { true }
    end
    has_permission_on [:csv_export], :to => [:generate_csv]
    has_permission_on [:report], :to => [:csv_reports, :csv_report_download, :pdf_reports, :pdf_report_download]
    has_permission_on [:icse_reports],
                      :to => [
                          :student_report_pdf,
                          :student_transcript,
                          :student_report_csv,
                      ] do
      if_attribute :icse_enabled? => is { true }
    end
    has_permission_on [:student_records],
                      :to => [
                          :individual_student_records
                      ]
  end

  role :manage_news do
    has_permission_on [:news],
                      :to => [
                          :index,
                          :load_news,
                          :load_comments,
                          :reset_news,
                          :show_pending_comments,
                          :show_approved_comments,
                          :add,
                          :add_comment,
                          :all,
                          :delete,
                          :delete_comment,
                          :approve_comment,
                          :edit,
                          :update,
                          :new,
                          :create,
                          :update,
                          :search_news_ajax,
                          :view,
                          :show,
                          :comment_view
                      ]
  end

  role :manage_timetable do
    includes :timetable_track
    includes :classroom_allocation
    has_permission_on [:class_timing_sets], :to => [
                                              :index,
                                              :new,
                                              :create,
                                              :edit,
                                              :update,
                                              :show,
                                              :destroy,
                                              :new_class_timings,
                                              :create_class_timings,
                                              :edit_class_timings,
                                              :update_class_timings,
                                              :delete_class_timings,
                                              :new_batch_class_timing_set,
                                              :list_batches,
                                              :add_batch,
                                              :remove_batch
                                          ]
    has_permission_on [:class_timings], :to => [:index, :edit, :destroy, :show, :new, :create, :update]
    has_permission_on [:weekday], :to => [:index, :week, :create, :get_class_timing_sets, :get_class_timing_set_for_edit, :list_batches]
    has_permission_on [:timetable],
                      :to => [:index,
                              :new_timetable,
                              :update_timetable,
                              :manage_batches,
                              :add_batch_timetable,
                              :remove_batch_timetable,
                              :view,
                              :edit_master,
                              :manage_timetables,
                              :manage_allocations,
                              :manage_work_allocations,
                              :load_work_allocations,
                              :load_manage_subject,
                              :update_employee_list,
                              :update_batch_list,
                              :assign_employee,
                              :remove_employee,
                              :summary,
                              :update_summary,
                              :batch_subject_utilization,
                              :batch_allocation_list,
                              :employees_hour_utilization,
                              :employee_hour_overlaps,
                              :load_batch_wise_summary,
                              :update_course_work_allotment,
                              :teachers_timetable,
                              :update_teacher_tt,
                              :update_employee_timetable,
                              :update_timetable_view,
                              :timetable_view_batches,
                              :destroy,
                              :employee_timetable,
                              :employee_timetable_pdf,
                              :update_employee_tt,
                              :student_view,
                              :update_student_tt,
                              :weekdays,
                              :settings,
                              :timetable,
                              :timetable_pdf,
                              :work_allotment
                      ]
    has_permission_on [:timetable_entries],
                      :to => [
                          :new,
                          :select_batch,
                          :new_entry,
                          :update_employees,
                          :delete_employee2,
                          :update_multiple_timetable_entries2,
                          :tt_entry_update2,
                          :tt_entry_noupdate2,
                          :update_batch_list
                      ]
    #    has_permission_on [:timetable],
    #      :to => [
    #      :index,
    #      :edit,
    #      :delete_subject,
    #      :select_class,
    #      :tt_entry_update,
    #      :tt_entry_noupdate,
    #      :update_multiple_timetable_entries,
    #      :update_timetable_view,
    #      :generate,
    #      :extra_class,
    #      :extra_class_edit,
    #      :list_employee_by_subject,
    #      :save_extra_class,
    #      :timetable,
    #      :weekdays,
    #      :view,
    #      :select_class2,
    #      :edit2,
    #      :update_employees,
    #      :update_multiple_timetable_entries2,
    #      :delete_employee2,
    #      :tt_entry_update2,
    #      :tt_entry_noupdate2,
    #      :timetable_pdf
    #    ]
  end
  role :manage_roll_number do
    has_permission_on [:student_roll_number], :to => [
                                                :index,
                                                :edit_sort_order_warning,
                                                :edit_sort_order,
                                                :update_sort_order,
                                                :edit_course_prefix,
                                                :update_course_prefix,
                                                :set_course_prefix,
                                                :create_course_prefix,
                                                :view_batches,
                                                :set_roll_numbers,
                                                :create_roll_numbers,
                                                :update_roll_numbers,
                                                :edit_roll_numbers,
                                                :edit_batch_prefix,
                                                :update_batch_prefix,
                                                :reset_batch_to_course_prefix,
                                                :create_roll_numbers,
                                                :update_roll_numbers,
                                                :reset_all_roll_numbers,
                                                :regenerate_all_roll_numbers,
                                                :update_roll_numbers_to_null,
                                                :save_changes_warning] do
      if_attribute :roll_number_enabled? => is { true }
    end
  end
  role :manage_roll_number_tutor do
    has_permission_on [:student_roll_number], :to => [
                                                :create_roll_numbers,
                                                :update_roll_numbers,
                                                :edit_batch_prefix,
                                                :update_batch_prefix,
                                                :reset_batch_to_course_prefix,
                                                :create_roll_numbers,
                                                :update_roll_numbers,
                                                :reset_all_roll_numbers,
                                                :regenerate_all_roll_numbers,
                                                :update_roll_numbers_to_null,
                                                :save_changes_warning
                                            ], :join_by => :and do
      if_attribute :roll_number_enabled? => is { true }
      if_attribute :is_a_batch_tutor? => is { true }
    end
    has_permission_on [:student_roll_number], :to => [
                                                :edit_roll_numbers,
                                                :set_roll_numbers
                                            ], :join_by => :and do
      if_attribute :employees => {:user => is { user }}
      if_attribute :roll_number_enabled? => is { true }
    end
  end

  #  role :manage_building_and_allocation do
  #    has_permission_on [:classroom_allocations], :to => [:index,
  #      :new,
  #      :view,
  #      :weekly_allocation,
  #      :date_specific_allocation,
  #      :render_classrooms,
  #      :delete_allocation,
  #      :find_allocations,
  #      :display_rooms,
  #      :update_allocation_entries,
  #      :override_allocations
  #    ]
  #    has_permission_on [:buildings], :to => [:index,
  #      :show,
  #      :update,
  #      :edit,
  #      :create,
  #      :new,
  #      :destroy
  #    ]
  #    has_permission_on [:classrooms], :to => [
  #      :index,
  #      :show,
  #      :update,
  #      :edit,
  #      :create,
  #      :new,
  #      :destroy,
  #      :list_weekly_activities,
  #      :list_date_specific_activities,
  #      :year
  #    ]
  #
  #  end

  role :classroom_allocation do
    has_permission_on [:classroom_allocations], :to => [:index,
                                                        :new,
                                                        :view,
                                                        :weekly_allocation,
                                                        :date_specific_allocation,
                                                        :render_classrooms,
                                                        :delete_allocation,
                                                        :find_allocations,
                                                        :display_rooms,
                                                        :update_allocation_entries,
                                                        :override_allocations
                                              ]
  end

  role :manage_building do
    has_permission_on [:buildings], :to => [:index,
                                            :show,
                                            :update,
                                            :edit,
                                            :create,
                                            :new,
                                            :destroy
                                  ]
    has_permission_on [:classrooms], :to => [
                                       :index,
                                       :show,
                                       :update,
                                       :edit,
                                       :create,
                                       :new,
                                       :destroy,
                                       :list_weekly_activities,
                                       :list_date_specific_activities,
                                       :year
                                   ]
    has_permission_on [:classroom_allocations], :to => [:index]
  end

  role :timetable_view do
    has_permission_on [:timetable], :to => [:index,
                                            :add_batch_timetable,
                                            :remove_batch_timetable,
                                            :view,
                                            :teachers_timetable,
                                            :update_teacher_tt,
                                            :update_timetable_view,
                                            :timetable_view_batches,
                                            :employee_timetable,
                                            :update_employee_tt,
                                            :update_employee_timetable,
                                            :employee_timetable_pdf,
                                            :student_view,
                                            :update_student_tt,
                                            :timetable,
                                            :timetable_pdf
                                  ]
    has_permission_on [:timetable_tracker], :to => [:index,
                                                    :swaped_timetable_report,
                                                    :swaped_timetable_report_csv,
                                                    :employee_report_details
                                          ]
    #    has_permission_on [:timetable], :to => [:index,:select_class,:view, :update_timetable_view, :timetable_pdf, :timetable]
  end

  role :student_attendance_view do
    has_permission_on [:attendance], :to => [:index, :report, :student_report]
    has_permission_on [:attendance_reports], :to => [:index, :subjectwise_report, :consolidated_report, :subject, :mode, :show, :year, :report, :filter, :student_details, :report_pdf, :filter_report_pdf]
    has_permission_on [:csv_export], :to => [:generate_csv]


    has_permission_on [:student_attendance], :to => [:index, :student, :leaves_report]
    has_permission_on [:attendance_reports], :to => [:day_wise_report,:day_wise_report_filter_by_course,:daily_report_batch_wise]do
      if_attribute :can_view_day_wise_report? => is {true}
    end
  end

  role :student_attendance_register do
    has_permission_on [:attendance], :to => [:index,:register,:register_attendance]
    has_permission_on [:attendances], :to => [:index, :list_subject, :show, :new, :create, :edit,:update, :destroy,:subject_wise_register,:daily_register,:quick_attendance,:notification_status,:list_subjects,:send_sms_for_absentees,:attendance_register_csv, :attendance_register_pdf,:save_attendance ,:lock_attendance,:unlock_attendance]
    has_permission_on [:student_attendance], :to => [:index]
    has_permission_on [:csv_export], :to => [:generate_csv]
    has_permission_on [:attendance_reports], :to => [:index, :consolidated_report, :subjectwise_report, :subject, :mode, :show, :year, :report, :filter, :student_details, :report_pdf, :filter_report_pdf] do
      if_attribute :has_required_controls? => is { true }
    end
  end

  role :manage_course_batch do
    has_permission_on [:configuration], :to => [:index]
    has_permission_on [:courses], :to => [:index, :manage_course, :assign_subject_amount, :edit_subject_amount, :destroy_subject_amount, :manage_batches, :inactivate_batch, :activate_batch, :find_course, :new, :create, :destroy, :edit, :update, :show, :update_batch, :grouped_batches, :create_batch_group, :edit_batch_group, :update_batch_group, :delete_batch_group]
    has_permission_on [:batches], :to => [:index, :new, :create, :destroy, :edit, :update, :show, :init_data, :assign_tutor, :update_employees, :assign_employee, :remove_employee, :batches_ajax, :batch_summary, :list_batches, :tab_menu_items, :get_tutors, :get_batch_span]
    has_permission_on [:subjects], :to => [:edit_elective_group, :set_elective_group_name, :index, :new, :create, :destroy, :edit, :update, :show, :destroy_elective_group, :update_batch_list, :load_subject_list, :import_subjects, :enable_elective_group_delete, :delete_component, :edit_component, :update_component]
    has_permission_on [:elective_groups], :to => [:index, :new, :create, :destroy, :edit, :update, :show, :new_elective_subject, :create_elective_subject, :edit_elective_subject, :update_elective_subject]
    has_permission_on [:student], :to => [:electives, :assigned_elective_subjects, :search_students, :assign_students, :unassign_students, :choose_elective, :remove_elective, :assign_all_students, :unassign_all_students, :profile, :guardians, :show_previous_details]
    has_permission_on [:batch_transfers],
                      :to => [
                          :index,
                          :show,
                          :transfer,
                          :attendance_transfer,
                          :graduation,
                          :subject_transfer,
                          :get_previous_batch_subjects,
                          :update_batch,
                          :assign_previous_batch_subject,
                          :assign_all_previous_batch_subjects,
                          :new_subject,
                          :create_subject
                      ]
    has_permission_on [:revert_batch_transfers], :to => [:index, :list_students, :revert_transfer]
  end

  role :subject_master do
    has_permission_on [:configuration], :to => [:index]
    has_permission_on [:student], :to => [:electives, :assigned_elective_subjects, :search_students, :assign_students, :unassign_students, :assign_all_students, :unassign_all_students]
    has_permission_on [:subjects], :to => [:edit_elective_group, :set_elective_group_name, :index, :new, :create, :destroy, :edit, :update, :show, :destroy_elective_group, :load_subject_list, :update_batch_list, :import_subjects, :enable_elective_group_delete,  :delete_component, :edit_component, :update_component]
    has_permission_on [:elective_groups], :to => [:index, :new, :create, :destroy, :edit, :update, :show, :new_elective_subject, :create_elective_subject, :edit_elective_subject, :update_elective_subject]
    includes :manage_subjects
  end

  role :academic_year do
    has_permission_on [:configuration], :to => [:index]
    has_permission_on [:academic_year],
                      :to => [
                          :index,
                          :add_course,
                          :migrate_classes,
                          :migrate_students,
                          :list_students,
                          :update_courses,
                          :upcoming_exams]
  end
  role :sms_management do
    includes :message_template_management
    has_permission_on [:configuration], :to => [:index]
    has_permission_on [:sms], :to => [:index, :settings, :update_general_sms_settings, :show_sms_messages, :send_sms, :birthday_sms]
    has_permission_on [:sms],
                      :to => [:students, :list_students, :batches, :sms_all, :employees, :list_employees, :departments, :all, :show_sms_logs, :user_type_selection, :load_student_sms_send ] do
      if_attribute :is_enabled => is { true }
    end
    # has_permission_on [:sms], :to => [:index, :settings, :students, :batches, :employees, :departments,:all, :update_general_sms_settings, :list_students, :sms_all, :list_employees, :show_sms_messages, :show_sms_logs]
  end
  role :event_management do

    has_permission_on [:event], :to => [:index, :show, :confirm_event, :cancel_event, :select_course, :event_group, :course_event, :remove_batch, :select_employee_department, :department_event, :remove_department, :edit_event, :new, :create, :update]
    has_permission_on [:calendar], :to => [:event_delete]
  end

  role :general_settings do
    has_permission_on [:configuration], :to => [:index, :settings, :permissions]
    has_permission_on [:single_access_tokens], :to => [:index, :new, :create, :destroy]
    has_permission_on [:student], :to => [:add_additional_details, :change_field_priority, :delete_additional_details, :edit_additional_details, :categories, :category_delete, :category_edit, :category_update]
  end

  role :manage_fee do

    includes :manage_finance_settings

    has_permission_on [:finance],
                      :to => [
                          :index,
                          :fees_index,
                          :fee_collection,
                          :fee_collection_create,
                          :fee_collection_delete,
                          :fee_collection_edit,
                          :fee_collection_update,
                          :fees_structure_dates,
                          :fee_collection_view,
                          :fee_collection_dates_batch,
                          :show_master_categories_list,
                          :master_fees,
                          :fees_particulars,
                          :fee_collection_batch_update,
                          #      :fees_student_structure_search,
                          #      :fees_student_structure_search_logic,
                          :fee_structure_dates,
                          :master_category_create,
                          :master_category_new,
                          :fees_particulars_new,
                          :fees_particulars_new2,
                          :fees_particulars_create,
                          :fees_particulars_create2,
                          :fee_collection_new,
                          :fee_collection_create,
                          :fee_discounts,
                          :fee_discount_new,
                          :load_discount_create_form,
                          :load_discount_batch,
                          :load_batch_fee_category,
                          :batch_wise_discount_create,
                          :category_wise_fee_discount_create,
                          :student_wise_fee_discount_create,
                          :update_master_fee_category_list,
                          :show_fee_discounts,
                          :edit_fee_discount,
                          :update_fee_discount,
                          :delete_fee_discount,
                          :collection_details_view,
                          :master_category_edit,
                          :master_category_update,
                          :master_category_delete,
                          :master_category_particulars,
                          :master_category_particulars_edit,
                          :master_category_particulars_update,
                          :master_category_particulars_delete,
                          :generate_fine,
                          :new_fine,
                          :fine_list,
                          :add_fine_slab,
                          :fine_slabs_edit_or_create,
                          :list_category_batch,
                          :particular_discount_applicable_students,
                          :generate_fee_receipt_pdf,
                          :generate_fee_receipt_pdf_new,
                          :generate_fee_receipt,
                          :generate_fee_receipt_text,
                          :fee_receipts,
                          :fee_reciepts_export_csv,
                          :fee_reciepts_export_pdf,
                          :get_advance_time,
                          :get_advance_search,
                          :get_collection_list,
                          :get_payee,
                          :finance_reports,
                          # tax related actions
                          :tax_index,
                          :tax_settings,
                          :master_particular_tax_slab_update
                      ]

    has_permission_on [:scheduled_jobs],
                      :to => [
                          :index
                      ]
    has_permission_on [:finance_extensions],
                      :to => [
                          :batch_discounts,
                          :discount_particular_allocation,
                          :fee_collections_for_batch,
                          :fee_structure_pdf,
                          :fees_structure_for_student,
                          :fees_student_structure,
                          :generate_overall_fee_receipt_pdf,
                          :list_students_by_batch_for_structure,
                          :load_fee_particulars,
                          :particulars_with_tabs,
                          :search_student_list_for_structure,
                          :show_discounts,
                          :show_particulars,
                          :structure_overview_pdf,
                          :student_fees_structure_pdf,
                          :structure_overview_pdf,
                          :student_fees_structure_pdf,
                          :update_collection_discount,
                          :update_collection_particular,
                          :update_instant_pay_all_discount,
                          :view_fees_structure,
                          :push_dj,
                          :test_invoice_number
                      ]
    has_permission_on [:tax_slabs],
                      :to => [:index, :new, :create, :edit, :update, :destroy]
    has_permission_on [:financial_years], :to => [
                                           :index,
                                           :new,
                                           :create,
                                           :edit,
                                           :update,
                                           :set_active,
                                           :update_active,
                                           :fetch_details,
                                           :delete_year
                                       ]
    has_permission_on [:master_fees], :to => [
                                        :index,
                                        :new_master_particular,
                                        :create_master_particular,
                                        :edit_master_particular,
                                        :update_master_particular,
                                        :delete_master_particular,
                                        :new_master_discount,
                                        :create_master_discount,
                                        :edit_master_discount,
                                        :update_master_discount,
                                        :delete_master_discount,
                                        # :manage_masters,
                                        :load_categories,
                                        :load_fee_particulars,
                                    ]
    has_permission_on [:advance_payment_fees], :to => [
                                      :advance_fees_index,
                                      :advance_fee_categories_list,
                                      :edit_advance_fee_category,
                                      :update_advance_fee_category,
                                      :advance_fees_category_new,
                                      :show_category_detail_fields,
                                      :advance_fees_category_create,
                                      :show_advance_fees_category_batches,
                                      :advance_fees_collection_index,
                                      :list_students_by_batch,
                                      :fee_head_by_student,
                                      :select_payment_mode,
                                      :submit_fees,
                                      :payment_history,
                                      :advance_fees_receipt_pdf,
                                      :generate_fee_receipt,
                                      :online_fees_receipt_pdf,
                                      :delete_advance_fee_payment_transaction
                                    ]
  end


  #manage_tax role : all tax specific actions
  #  role :manage_tax do
  #    has_permission_on [:finance], :to => [:tax_index, :tax_settings, :master_particular_tax_slab_update]
  #
  #    has_permission_on [:finance_extensions], :to => [:tax_report, :update_tax_report, :show_date_filter,
  #      :tax_report_pdf]
  #
  #    has_permission_on [:tax_slabs], :to => [:index, :new, :create, :edit, :update, :destroy]
  #  end

  role :fee_submission do
    has_permission_on [:finance],
                      :to => [
                          :index,
                          :fees_index,
                          :search_logic,
                          :fees_defaulters,
                          :fees_submission_batch,
                          :update_fees_collection_dates,
                          :load_fees_submission_batch,
                          :update_ajax,
                          :update_batches,
                          :update_fees_collection_dates_defaulters,
                          :fees_defaulters_students,
                          :fees_student_dates,
                          :pay_fees_defaulters,
                          :fees_submission_save,
                          :fees_submission_student,
                          :fee_particulars_update,
                          :student_or_student_category,
                          :update_fine_ajax,
                          :student_fee_receipt_pdf,
                          :update_student_fine_ajax,
                          :update_student_auto_fine_ajax,
                          :update_defaulters_fine_ajax,
                          :fee_defaulters_pdf,
                          :select_payment_mode,
                          :student_wise_fee_payment,
                          :fees_submission_index,
                          :fees_student_search,
                          :fees_received,
                          :load_particular_fee_categories,
                          :load_fee_category_particulars,
                          :particular_wise_fee_discount_create,
                          :particular_discount_applicable_students,
                          :fee_collection_batch_update_for_fee_collection,
                          :generate_fee_receipt_pdf,
                          :generate_fee_receipt_pdf_new,
                          :generate_fee_receipt,
                          :fee_receipts,
                          :get_advance_time,
                          :get_advance_search,
                          :get_collection_list,
                          :get_payee,
                          :finance_reports,
                          :fee_reciepts_export_csv,
                          :fee_reciepts_export_pdf

                      ]


    has_permission_on [:finance_extensions], :to => [
                                               :add_pay_all_manual_fine,
                                               :delete_instant_pay_all_fine,
                                               :create_instant_pay_all_discount,
                                               :delete_instant_pay_all_discount,
                                               #      :edit_instant_pay_all_discount,
                                               :new_instant_pay_all_discount,
                                               :search_students_for_pay_all_fees,
                                               :list_students_by_batch,
                                               :pay_all_fees_index,
                                               :student_search_autocomplete,
                                               :pay_all_fees,
                                               :pay_all_fees_receipt_pdf,
                                               :pay_fees_in_particular_wise,
                                               :particular_wise_fee_payment,
                                               :particular_wise_fee_pay_pdf,
                                               :create_instant_particular,
                                               :new_instant_particular,
                                               :delete_student_particular,
                                               :paginate_paid_fees,
                                               :new_instant_discount,
                                               :create_instant_discount,
                                               :delete_student_discount,
                                               :generate_overall_fee_receipt_pdf,
                                               :fetch_waiver_amount_pay_all,
                                               :fetch_waiver_amount_collection_wise,
                                               :remove_pay_all_auto_fine,
                                               :fetch_total_fine_amount_for_pay_all
                                           ]  
    
  end

  role :approve_reject_payslip do
    has_permission_on [:finance],
                      :to => [
                          :index,
                          :employee_payslip_approve,
                          :payslip_revert_transaction,
                          :employee_payslip_reject,
                          :employee_payslip_accept_form,
                          :employee_payslip_reject_form,
                          :view_monthly_payslip_pdf,
                          :search_ajax,
                          :view_employee_payslip,
                          :payslip_index,
                      ]
    has_permission_on [:finance], :to => [:view_monthly_payslip] do
      if_attribute :approve_reject_privilege => true
    end
    has_permission_on [:employee_payslips], :to => [
                                              :approve_payslips,
                                              :approve_payslips_range,
                                              :view_payslip_pdf
                                          ]
    has_permission_on [:employee_payslips], :to => [
                                              :payslip_generation_list,
                                              :view_all_employee_payslip,
                                              :payslip_for_payroll_group,
                                              :payslip_for_employees,
                                              :view_all_rejected_payslips,
                                              :view_payslip,
                                              :view_past_payslips,
                                              :view_employee_past_payslips
                                          ] do
      if_attribute :approve_reject_privilege => true
    end
    has_permission_on [:csv_export], :to => [:generate_csv]
    has_permission_on [:payroll_groups], :to => [:index, :show] do
      if_attribute :approve_reject_privilege => true
    end
    has_permission_on [:payroll], :to => [
                                    :assigned_employees,
                                    :show,
                                    :employee_list
                                ] do
      if_attribute :approve_reject_privilege => true
    end
    includes :manage_hr_reports
  end

  role :finance_reports do
    has_permission_on [:finance_reports],
                      :to => [:index, :load_batches, :update_dates, :payment_mode_summary, :particular_wise_daily,
                              :particular_wise_student_transaction, :download_report]
    has_permission_on [:finance_extensions],
                      :to => [
                          :tax_report,
                          :update_tax_report,
                          :show_date_filter,
                          :tax_report_pdf
                      ]
    has_permission_on [:finance],
      :to => [
      :index,
      :fees_index,
      :monthly_report,
      :update_monthly_report,
      :show_date_filter,
      :show_compare_date_filter,
      :salary_department,
      :salary_employee,
      :donations_report,
      :salary_employee_csv,
      :donation_report_csv,
      :fees_report,
      :batch_fees_report,
      :course_wise_collection_report,
      :month_date,
      :compare_report,
      :report_compare,
      :graph_for_compare_monthly_report,
      :transaction_pdf,
      :graph_for_update_monthly_report,
      :finance_reports,
      :income_details,
      :expense_details,
      :expense_details_pdf,
      :income_details_pdf,
      :view_employee_payslip,
      :cancelled_transaction_reports,
      :advanced_cancelled_transaction_reports,
      :fee_reciepts_export_csv,
      :fee_reciepts_export_pdf,
      :fee_receipts,
      :get_advance_time,
      :get_advance_search,
      :get_collection_list,
      :get_payee,
      :generate_fee_receipt_pdf,
      :generate_fee_receipt_pdf_new,
      :generate_fee_receipt
    ]


    has_permission_on [:report],
                      :to => [
                          :index,
                          :search_student,
                          :search_ajax,
                          :student_fees_headwise_report,
                          :student_fees_headwise_report_csv,
                          :student_fees_headwise_report_pdf,
                          :fees_head_wise_report,
                          :batch_fees_headwise_report,
                          :fee_collection_report,
                          :batch_head_wise_fees_csv,
                          :collection_report_csv,
                          :batch_selector,
                          :fee_collection_head_wise_report,
                          :update_fees_collections,
                          :fee_collection_head_wise_report_csv,
                          :csv_reports,
                          :batch_list,
                          :batch_list_active,
                          :csv_report_download,
                          :student_wise_fee_defaulters,
                          :student_wise_fee_defaulters_csv,
                          :send_sms,
                          :course_fee_defaulters,
                          :course_fee_defaulters_csv,
                          :fee_collection_details,
                          :fee_collection_details_csv,
                          :batch_list,
                          :batch_students,
                          :batch_students_csv,
                          :batch_fee_defaulters,
                          :batch_fee_defaulters_csv,
                          :batch_fee_collections,
                          :batch_fee_collections_csv,
                          :students_fee_defaulters,
                          :students_fee_defaulters_csv,
                          :batch_details,
                          :student_wise_fee_collections,
                          :student_wise_fee_collections_csv,
                          :fee_defaulters_columns,
                          :fee_collection_selectors,
                          :pdf_reports,
                          :pdf_report_download

                      ]
    has_permission_on [:advance_payment_fees], :to => [
                        :report_index,
                        :search_students,
                        :list_student_wallet_details,
                        :wallet_transactions_by_student,
                        :category_wise_transaction_by_student,
                        :wallet_deduction_transaction_report,
                        :transaction_pdf,
                        :wallet_credit_transaction_report,
                        :wallet_debit_transaction_report,
                        :course_wise_monthly_report,
                        :batch_wise_monthly_income_report,
                        :category_wise_collections,
                        :batch_wise_monthly_expense_report
                      ]
  end

  role :revert_transaction do
    has_permission_on [:finance],
                      :to => [
                          :index,
                          :delete_transaction_for_student,
                          :delete_transaction_by_batch,
                          :transaction_deletion,
                          :delete_transaction_fees_defaulters,
                          :deleted_transactions,
                          :update_deleted_transactions,
                          :list_deleted_transactions,
                          :search_fee_collection,
                          :transaction_filter_by_date,
                          :transactions_advanced_search,
                          :delete_transaction,
                          :delete_transaction_for_particular_wise_fee_pay,
                          :transactions,
                          :revert_fee_refund,
                          :generate_fee_receipt_pdf,
                          :generate_fee_receipt_pdf_new,
                          :fee_receipts,
                          :get_advance_time,
                          :get_advance_search,
                          :get_collection_list,
                          :get_payee,
                          :finance_reports
                      ]

    has_permission_on [:finance_extensions],
                      :to => [
                          :delete_multi_fees_transaction,
                          :generate_overall_fee_receipt_pdf,
                          :fetch_waiver_amount_pay_all,
                          :fetch_waiver_amount_collection_wise
                      ]
    includes :fee_submission
  end

  role :miscellaneous do
    has_permission_on [:finance],
                      :to => [
                          :index,
                          :categories,
                          :donation,
                          :donation_receipt,
                          :expense_create,
                          :income_create,
                          :category_create,
                          :category_delete,
                          :category_edit,
                          :category_update,
                          :asset_liability,
                          :liability,
                          :create_liability,
                          :view_liability,
                          :new_liability,
                          :each_liability_view,
                          :asset,
                          :create_asset,
                          :new_asset,
                          :view_asset,
                          :each_asset_view,
                          :edit_liability,
                          :update_liability,
                          :delete_liability,
                          :edit_asset,
                          :update_asset,
                          :delete_asset,
                          :categories_new,
                          :categories_create,
                          :donation_receipt_pdf,
                          :donations,
                          :donors_list,
                          :donors_list_pdf,
                          :expense_list,
                          :expense_list_update,
                          :income_list,
                          :income_list_update,
                          :donation_edit,
                          :donation_delete,
                          :income_list_pdf,
                          :expense_list_pdf,
                          :asset_pdf,
                          :liability_pdf,
                          :transactions,
                          :asset_liability,
                          :delete_transaction,
                          :income_details,
                          :income_details_pdf,
                          :add_additional_details_for_donation,
                          :edit_additional_details_for_donation,
                          :delete_additional_details_for_donation,
                          :change_field_priority_for_donation
                      ]
    has_permission_on [:scheduled_jobs],
                      :to => [
                          :index
                      ]
    has_permission_on [:report],
                      :to => [
                          :donation_list_csv
                      ]
  end

  role :manage_refunds do
    has_permission_on [:finance],
                      :to => [
                          :index,
                          :fees_index,
                          :fees_refund,
                          :create_refund,
                          :new_refund,
                          :apply_refund,
                          :refund_student_search,
                          :fees_refund_dates,
                          :fees_refund_student,
                          :view_refunds,
                          :refund_filter_by_date,
                          :search_fee_refunds,
                          :list_refunds,
                          :fee_refund_student_pdf,
                          :refund_search_pdf,
                          :refund_student_view,
                          :refund_student_view_pdf,
                          :view_refund_rules,
                          :list_refund_rules,
                          :edit_refund_rules,
                          :refund_rule_update,
                          :refund_rule_delete,
                          :revert_fee_refund
                      ]
  end

  role :manage_finance_settings do

    has_permission_on [:finance_settings],
                      :to => [
                          :configure_category,
                          :fee_general_settings,
                          # :fee_settings,
                          :fees_receipt_preview,
                          :fees_receipt_settings_update_form,
                          :get_printer_message,
                          :index,
                          :load_fee_category_configurations,
                          :receipt_pdf_settings,
                          :receipt_print_settings
                      ]

    has_permission_on [:fee_accounts],
                      :to => [:index, :new, :create, :edit, :destroy, :update, :manage]

    has_permission_on [:receipt_templates],
                      :to => [:index, :new, :create, :edit, :update, :destroy, :show, :template_preview]

    has_permission_on [:receipt_sets],
                      :to => [:index, :new, :create, :edit, :destroy, :update]

  end
  
  role :fees_submission_without_discount do
   
   has_permission_on [:finance],
      :to => [
      :index,
      :fees_index,
      :search_logic,
      :fees_defaulters,
      :fees_submission_batch,
      :update_fees_collection_dates,
      :load_fees_submission_batch,
      :update_ajax,
      :update_batches,
      :update_fees_collection_dates_defaulters,
      :fees_defaulters_students,
      :fees_student_dates,
      :pay_fees_defaulters,
      :fees_submission_save,
      :fees_submission_student,
      :fee_particulars_update,
      :student_or_student_category,
      :update_fine_ajax,
      :student_fee_receipt_pdf,
      :update_student_fine_ajax,
      :update_student_auto_fine_ajax,
      :update_defaulters_fine_ajax,
      :fee_defaulters_pdf,
      :select_payment_mode,
      :student_wise_fee_payment,
      :fees_submission_index,
      :fees_student_search,
      :fees_received,
      :load_particular_fee_categories,
      :load_fee_category_particulars,
      :particular_wise_fee_discount_create,
      :particular_discount_applicable_students,
      :fee_collection_batch_update_for_fee_collection,
      :generate_fee_receipt_pdf,
      :generate_fee_receipt_pdf_new,
      :generate_fee_receipt,
      :fee_receipts,
      :get_advance_time,
      :get_advance_search,
      :get_collection_list,
      :get_payee,
      :finance_reports,
      :fee_reciepts_export_csv,
      :fee_reciepts_export_pdf
    ]

    has_permission_on [:finance_extensions], :to => [
      :add_pay_all_manual_fine,
      :delete_instant_pay_all_fine,
      :create_instant_pay_all_discount,
      :delete_instant_pay_all_discount,
      #  :edit_instant_pay_all_discount,
      :new_instant_pay_all_discount,
      :search_students_for_pay_all_fees,
      :list_students_by_batch,
      :pay_all_fees_index,
      :student_search_autocomplete,
      :pay_all_fees,
      :pay_all_fees_receipt_pdf,
      :pay_fees_in_particular_wise,
      :particular_wise_fee_payment,
      :particular_wise_fee_pay_pdf,
      :create_instant_particular,
      :new_instant_particular,
      :delete_student_particular,
      :paginate_paid_fees,
      :generate_overall_fee_receipt_pdf,
      :remove_pay_all_auto_fine
    ]  
    
  end
 
  role :finance_control do

    includes :manage_fee
    includes :fee_submission
    includes :approve_reject_payslip
    includes :finance_reports
    includes :manage_refunds
    includes :payroll_management
    includes :miscellaneous
    includes :revert_transaction
    includes :manage_tax
    includes :manage_finance_settings
    includes :fees_submission_without_discount 

    has_permission_on [:xml],
                      :to => [
                          :create_xml,
                          :index,
                          :settings,
                          :download
                      ]


  end

  role :hr_settings do
    includes :employee_search
    has_permission_on [:employee],
                      :to => [
                          :settings,
                          :add_category,
                          :edit_category,
                          :delete_category,
                          :add_position,
                          :edit_position,
                          :delete_position,
                          :add_department,
                          :edit_department,
                          :delete_department,
                          :add_grade,
                          :edit_grade,
                          :delete_grade,
                          :add_bank_details,
                          :edit_bank_details,
                          :delete_bank_details,
                          :add_additional_details,
                          :edit_additional_details,
                          :delete_additional_details,
                          :change_field_priority,
                      ]
    has_permission_on [:payroll_groups], :to => [
                                           :working_day_settings,
                                           :update_working_day_settings
                                       ]
    has_permission_on [:employee_attendance], :to => [
                                                :list_leave_types,
                                                :add_leave_types,
                                                :edit_leave_types,
                                                :delete_leave_types
                                            ]
    has_permission_on [:payroll], :to => [:settings]
    has_permission_on :leave_groups,
                      :to => [
                          :index,
                          :new,
                          :create,
                          :edit,
                          :update,
                          :show,
                          :delete_group,
                          :add_leave_types,
                          :add_employees,
                          :manage_employees,
                          :remove_leave_type,
                          :save_employees,
                          :advanced_search,
                          :remove_employee,
                          :add_individual_leave_type,
                          :manage_leave_group,
                          :leave_group_details
                      ]
  has_permission_on :leave_years, 
                    :to => [
                            :index,
                            :autocredit_setting,
                            :credit_date_setting,
                            :reset_setting,
                            :leave_process_settings,
                            :new,
                            :create,
                            :edit,
                            :update,
                            :set_active,
                            :leave_process,
                            :update_active,
                            :fetch_details,
                            :delete_year,
                            :settings,
                            :process_leaves,
                            :leave_records,
                            :end_year_process_detail,
                            :retry_employee_reset,
                            :retry_reset,
                            :leave_record_filter,
                            :leave_reset_settings,
                            :confirmation_box,
                            :leave_credit_date_settings
                            ]                 
  end

  role :manage_employee do
    includes :employee_search
    has_permission_on [:report],
                      :to => [
                          :csv_reports,
                          :csv_report_download,
                          :pdf_reports,
                          :pdf_report_download
                      ]
    has_permission_on [:employee_attendance],
                      :to => [
                          :list_department_leave_reset,
                          :employee_search_ajax,
                          :employee_search_ajax_reset,
                          :employee_leave_details,
                          :reset_logs,
                          :reset_leaves,
                          :reset_all,
                          :reset_all_employees,
                          :reset_by_leave_groups,
                          :reset_by_leave_groups_modal,
                          :employee_reset_logs,
                          :retry_reset,
                          :retry_employee_reset,
                          :settings,
                          :leave_applications,
                          :leave_application,
                          :view_attendance,
                          :credit_logs,
                          :credit_leaves,
                          :credit_employee_search_ajax,
                          :list_department_leave_credit,
                          :credit_all,
                          :credit_by_leave_groups,
                          :credit_all_employees,
                          :employee_credit_logs,
                          :credit_by_leave_groups_modal
                      ]
    has_permission_on [:payroll],
                      :to => [
                          :manage_payroll,
                          :calculate_employee_payroll_components,
                          :add_employee_payroll,
                          :create_employee_payroll
                      ]
    has_permission_on [:employee],
                      :to => [
                          :hr,
                          :admission1,
                          :employee_attendance,
                          :remove,
                          :remove_subordinate_employee,
                          :change_to_former,
                          :delete,
                          :admission1,
                          :update_positions,
                          :edit1,
                          :edit_personal,
                          :admission2,
                          :edit2,
                          :edit_contact,
                          :admission3,
                          :edit3,
                          :admission3_1,
                          :admission3_2,
                          :edit3_1,
                          :admission4,
                          :change_reporting_manager,
                          :reporting_manager_search,
                          :update_reporting_manager_name,
                          :edit4,
                          :select_reporting_manager,
                          :show,
                          :subject_assignment,
                          :update_subjects,
                          :select_department,
                          :update_employees,
                          :assign_employee,
                          :remove_employee,
                          :select_department_employee,
                          :employee_management,
                          :edit_privilege,
                          :leave_management,
                          :update_employees_select,
                          :leave_list,
                          :update_activities,
                          :payslip,
                          :profile_payroll_details,
                          :view_payslip,
                          :update_monthly_payslip
                      ]
    has_permission_on [:employee_payslips], :to => [:view_payslip_pdf]
    has_permission_on [:scheduled_jobs], :to => [:index]
    has_permission_on [:archived_employee], :to => [:profile_payroll_details, :change_to_present]
  end

  role :employee_reports do
    includes :employee_search
    includes :manage_hr_reports
    has_permission_on [:employee],
                      :to => [
                          :hr,
                          :payroll_and_payslips
                      ]
    has_permission_on [:finance], :to => [:view_monthly_payslip]
    has_permission_on [:report], :to => [
                                   :index,
                                   :employees,
                                   :employees_csv
                               ]
    has_permission_on [:report], :to => [:former_employees, :former_employees_csv] do
      if_attribute :search_privilege => true
    end
    has_permission_on [:report], :to => [:employee_subject_association, :employee_subject_association_csv] do
      if_attribute :subject_association_privilege => true
    end
    has_permission_on [:report], :to => [:employee_payroll_details, :employee_payroll_details_csv] do
      if_attribute :payroll_privilege => true
    end
    has_permission_on [:employee_payslips], :to => [:view_payslip]
    has_permission_on [:employee], :to => [
                                     :payslip,
                                     :profile_payroll_details,
                                     :view_payslip,
                                     :update_monthly_payslip,
                                     :employee_attendance
                                 ]
    has_permission_on [:archived_employee], :to => [
                                              :payslip,
                                              :profile_payroll_details,
                                          ]
    has_permission_on [:employee_payslips], :to => [:view_payslip_pdf]
    has_permission_on [:employee_attendance], :to => [:report, :leave_balance_report, :additional_leave_detailed, :view_attendance, :leave_application]
  end

  role :employee_attendance do
    includes :employee_search
    has_permission_on [:employee],
                      :to => [
                          :hr,
                          :employee_attendance,
                          :edit_leave_balance,
                          :add_individual_leave,
                          :remove_individual_leave,
                          :employee_leave_count_edit,
                          :employee_leave_count_update,
                          :view_attendance
                      ]
    has_permission_on [:employee_attendances],
                      :to => [
                          :index,
                          :show,
                          :new,
                          :create,
                          :edit,
                          :update,
                          :destroy

                      ]
    has_permission_on [:employee_attendance],
                      :to => [
                          :my_leaves,
                          :employee_leaves,
                          :report,
                          :leave_balance_report,
                          :report_pdf,
                          :leave_management,
                          :update_attendance_form,
                          :filter_attendance_report,
                          :update_filterd_attendance_report,
                          :filter_attendance_report,
                          :update_filterd_attendance_report,
                          :update_attendance_report,
                          :individual_leave_application,
                          :update_employees_select,
                          :leave_list,
                          :leave_app,
                          :employee_attendance_pdf,
                          :employee_leave_reset_all,
                          :update_employee_leave_reset_all,
                          :reset_all_employees,
                          :reset_by_leave_groups,
                          :reset_by_leave_groups_modal,
                          :list_department_leave_reset,
                          :update_department_leave_reset,
                          :credit_employee_search_ajax,
                          :employee_search_ajax_reset,
                          :employees_list,
                          :employee_leave_details,
                          :employee_wise_leave_reset,
                          :additional_leave_detailed,
                          :additional_leave_detailed_pdf,
                          :additional_leave_report_pdf,
                          :additional_leave_detailed_report_pdf,
                          :settings,
                          :reset_logs,
                          :reset_leaves,
                          :reset_all,
                          :reset_employee_leaves,
                          :employee_reset_logs,
                          :list_failed_employees,
                          :retry_leave_creation,
                          :retry_reset,
                          :retry_employee_reset,
                          :view_attendance,
                          :leave_application,
                          :leave_applications
                      ]
    has_permission_on [:report], :to => [:csv_reports, :csv_report_download, :pdf_reports, :pdf_report_download]
    has_permission_on [:csv_export], :to => [:generate_csv]
  end

  role :payroll_and_payslip do
    includes :employee_search
    includes :manage_hr_reports
    has_permission_on [:payroll_categories], :to => [
                                               :index,
                                               :new,
                                               :create,
                                               :edit,
                                               :update,
                                               :destroy,
                                               :show,
                                               :hr_formula_form,
                                               :validate_formula
                                           ]
    has_permission_on [:payroll_groups], :to => [
                                           :new,
                                           :create,
                                           :edit,
                                           :update,
                                           :destroy,
                                           :payslip_generation,
                                           :lop_settings,
                                           :categories_formula,
                                           :save_lop_settings
                                       ]
    has_permission_on [:employee],
                      :to => [
                          :hr,
                          :payroll_and_payslips,
                          :payslip,
                          :view_payslip,
                          :profile_payroll_details,
                          :update_monthly_payslip
                      ]
    has_permission_on [:employee_payslips], :to => [
                                              :generate_payslips,
                                              :generate_all_payslips,
                                              :view_outdated_employees,
                                              :save_employee_payslips,
                                              :generate_employee_payslip,
                                              :create_employee_wise_payslip,
                                              :view_employee_pending_payslips,
                                              :view_payslip_pdf,
                                              :revert_employee_payslip,
                                              :revert_all_payslips,
                                              :edit_payslip,
                                              :update_payslip,
                                              :rejected_payslips,
                                              :view_employees_with_lop,
                                              :view_regular_employees,
                                              :view_outdated_employees,
                                              :payslip_settings,
                                              :update_payslip_settings,
                                              :view_sample_payslip,
                                              :calculate_lop_values
                                          ]
    has_permission_on [:employee_payslips], :to => [
                                              :payslip_generation_list,
                                              :view_all_employee_payslip,
                                              :payslip_for_payroll_group,
                                              :payslip_for_employees,
                                              :view_all_rejected_payslips,
                                              :view_payslip,
                                              :view_past_payslips,
                                              :view_employee_past_payslips
                                          ] do
      if_attribute :approve_reject_privilege => true
    end
    has_permission_on [:payroll], :to => [
                                    :assign_employees,
                                    :remove_from_payroll_group,
                                    :create_employee_payroll,
                                    :add_employee_payroll,
                                    :calculate_employee_payroll_components,
                                    :show_warning,
                                    :manage_payroll
                                ]
    has_permission_on [:payroll_groups], :to => [:index, :show] do
      if_attribute :approve_reject_privilege => true
    end
    has_permission_on [:payroll], :to => [
                                    :assigned_employees,
                                    :show,
                                    :employee_list
                                ] do
      if_attribute :approve_reject_privilege => true
    end
    has_permission_on [:finance], :to => [:view_monthly_payslip] do
      if_attribute :approve_reject_privilege => true
    end
    has_permission_on [:csv_export], :to => [:generate_csv]
    has_permission_on [:archived_employee], :to => [:profile_payroll_details]
  end

  role :employee_search do
    has_permission_on [:archived_employee],
                      :to => [
                          :profile,
                          :profile_general,
                          :profile_personal,
                          :profile_address,
                          :profile_contact,
                          :profile_bank_details,
                          :profile_additional_details,
                          :profile_pdf,
                          :show
                      ]
    has_permission_on [:employee],
                      :to => [
                          :search,
                          :view_all,
                          :search_ajax,
                          :profile,
                          :profile_pdf,
                          :activities,
                          :employees_list,
                          :advanced_search,
                          :advanced_search_pdf,
                          :hr,
                          :profile_general,
                          :profile_personal,
                          :profile_address,
                          :profile_contact,
                          :profile_bank_details,
                          :profile_additional_details,
                      ]
    has_permission_on [:timetable],
                      :to => [
                          :employee_timetable,
                          :employee_timetable_pdf,
                          :update_employee_tt
                      ]
    has_permission_on [:csv_export], :to => [:generate_csv]
    has_permission_on [:report], :to => [:csv_reports, :csv_report_download, :pdf_reports, :pdf_report_download]
  end

  role :employee_timetable_access do
    includes :timetable_track
    has_permission_on [:timetable], :to => [:employee_timetable, :update_employee_tt, :timetable_pdf]
    #    has_permission_on [:employee], :to => [:timetable,:timetable_pdf]
  end

  role :manage_users do
    has_permission_on [:user],
                      :to => [
                          :index,
                          :search_user_ajax,
                          :all_users,
                          :create,
                          :profile,
                          :list_user,
                          :user_change_password,
                          :delete,
                          :edit_privilege,
                          :login,
                          :user_filters,
                          :block_user,
                          :unblock_user
                      ]
    has_permission_on [:employee],
                      :to => [
                          :select_reporting_manager,
                          :update_reporting_manager_name,
                          :edit1,
                          :profile,
                          :profile_pdf,
                          :edit_personal,
                          :edit2,
                          :edit_contact,
                          :edit3,
                          :admission3_1,
                          :profile_general,
                          :profile_personal,
                          :profile_address,
                          :profile_contact,
                          :profile_bank_details,
                          :profile_payroll_details,
                          :profile_additional_details,
                          :view_payslip,
                          :view_attendance,
                          :profile,
                          :activities,
                          :profile_pdf,
                      ]
    has_permission_on [:employee],
                      :to => [
                          :change_reporting_manager,
                      ] do
      if_attribute :id => is_not { user.id }
    end
    has_permission_on [:employee],
                      :to => [
                          :delete,
                          :change_to_former,
                          :remove,
                          :remove_subordinate_employee
                      ] do
      if_attribute :employee_entry => {:associate_employees => does_not_contain { user.employee_entry }}
    end

    has_permission_on [:student],
                      :to => [
                          :profile,
                          :edit,
                          :profile_pdf,
                          :add_guardian,
                          :admission3_1,
                          :guardians,
                          :admission4,
                          :previous_data,
                          :previous_data_from_profile,
                          :previous_subject,
                          :save_previous_subject,
                          :delete_previous_subject,
                          :show_previous_details,
                          :previous_data_edit,
                          :edit_admission4,
                          :edit_guardian,
                          :del_guardian,
                          :admission1_2,
                          :render_batch_list,
                          :set_roll_number_prefix,
                          :search_ajax,
                          :reports,
                          :fees,
                          :fee_details,
                          :my_subjects,
                          :choose_elective,
                          :remove_elective,
                          :change_to_former,
                          :delete,
                          :destroy,
                          :remove,
                          :generate_tc_pdf,
                          :exam_report,
                          :activities,
                          :update_activities,
                          :destroy_dependencies,
                          :student_fees_preference,
                          :unlink_sibling
                      ]
    has_permission_on [:scheduled_jobs],
                      :to => [
                          :index
                      ]
    has_permission_on [:timetable],
                      :to => [
                          :employee_timetable,
                          :employee_timetable_pdf,
                          :update_employee_tt
                      ]
    has_permission_on [:exam],
                      :to => [
                          :profile,
                          :profile_pdf,
                          :student_wise_generated_report,
                          :generated_report,
                          :generated_report4_pdf,
                          :graph_for_generated_report,
                          :academic_report,
                          :previous_years_marks_overview,
                          :previous_years_marks_overview_pdf,
                          :graph_for_previous_years_marks_overview,
                          :generated_report3,
                          :graph_for_generated_report3,
                          :generated_report4,
                          :student_transcript,
                          :student_transcript_pdf,
                          :combined_grouped_exam_report_pdf,
                          :consolidated_exam_report,
                          :generated_report_pdf,
                          :consolidated_exam_report_pdf,
                      ]
    has_permission_on [:report], :to => [:csv_reports, :pdf_reports]
    has_permission_on [:student_attendance], :to => [:student, :leaves_report, :month, :student_report]
    has_permission_on [:finance], :to => [:refund_student_view, :refund_student_view_pdf]
    has_permission_on [:cce_reports],
                      :to => [
                          :student_transcript,
                          :student_report_pdf
                      ] do
      if_attribute :cce_enabled? => is { true }
    end
    has_permission_on [:csv_export], :to => [:generate_csv]
    has_permission_on [:report], :to => [:csv_reports, :csv_report_download, :pdf_reports, :pdf_report_download]
    has_permission_on [:remarks], :to => [:custom_remark_list, :list_custom_remarks]
    has_permission_on [:remarks], :to => [:remarks_history, :remarks_pdf, :remarks_csv] do
      if_attribute :is_deleted => is { false }
    end
    has_permission_on [:icse_reports],
                      :to => [
                          :student_report_pdf,
                          :student_transcript,
                          :student_report_csv,
                      ] do
      if_attribute :icse_enabled? => is { true }
    end
    has_permission_on [:student_records],
                      :to => [
                          :individual_student_records
                      ]
  end

  # admin privileges
  role :admin do
    includes :archived_exam_reports
    includes :open
    includes :reports_view
    includes :timetable_track
    includes :manage_building
    includes :finance_control
    includes :manage_roll_number
    includes :manage_student_record
    includes :manage_student_attachment
    includes :manage_student_attachment_categories
    includes :manage_transfer_certificate
    includes :manage_feature_access_settings
    includes :manage_message
    includes :manage_gradebook
    includes :certificate_management
    includes :id_card_management
    includes :manage_subjects
    includes :manage_groups
    includes :message_template_management

    has_permission_on [:advance_payment_fees], :to => [:advance_fees_index,
                                                :advance_fees_category_new,
                                                :advance_fees_category_create,
                                                :advance_fees_collection_index,
                                                :list_students_by_batch,
                                                :fee_head_by_student,
                                                :select_payment_mode,
                                                :submit_fees,
                                                :advance_fees_receipt_pdf,
                                                :generate_fee_receipt,
                                                :online_fees_receipt_pdf,
                                                :delete_advance_fee_payment_transaction,
                                                :report_index,
                                                :list_student_wallet_details,
                                                :wallet_transactions_by_student,
                                                :category_wise_transaction_by_student,
                                                :wallet_particular_report_by_collection,
                                                :wallet_deduction_transaction_report,
                                                :transaction_pdf,
                                                :wallet_credit_transaction_report,
                                                :wallet_debit_transaction_report,
                                                :course_wise_monthly_report,
                                                :batch_wise_monthly_income_report,
                                                :batch_wise_monthly_expense_report,
                                                :search_students,
                                                :advance_fee_categories_list,
                                                :delete_advance_fee_category,
                                                :edit_advance_fee_category,
                                                :update_advance_fee_category,
                                                :show_advance_fees_category_batches,
                                                :advance_fee_students,
                                                :payment_history,
                                                :category_wise_collections
                                              ]

    has_permission_on [:reminder], :to => [
                                     #      :reminder,
                                     #      :sent_reminder,
                                     #      :view_sent_reminder,
                                     :delete_reminder_by_sender,
                                     :delete_reminder_by_recipient,
                                     :view_reminder,
                                     :mark_unread,
                                     :pull_reminder_form,
                                     :send_reminder,
                                     :reminder_actions,
                                     :sent_reminder_delete,
                                     #      :create_reminder,
                                     :to_employees,
                                     :to_students,
                                     :to_parents,
                                     :update_recipient_list,
                                     :update_recipient_list1,
                                     :update_recipient_list2,
                                     :model_box

                                 ]
    has_permission_on [:reminder],
                      :to => [
                          :reminder_attachments
                      ]
    has_permission_on [:user], :to => [:block_user, :unblock_user, :search_user_ajax, :user_filters, :edit_privilege, :index, :edit, :create, :user_change_password, :delete, :list_user, :profile, :all_users, :dashboard, :login, :logout, :show_quick_links, :manage_quick_links, :login]
    has_permission_on [:weekday], :to => [:index, :week, :list_batches, :get_class_timing_sets, :get_class_timing_set_for_edit, :create]
    has_permission_on [:class_timing_sets], :to => [
                                              :index,
                                              :new,
                                              :create,
                                              :edit,
                                              :update,
                                              :show,
                                              :destroy,
                                              :new_class_timings,
                                              :create_class_timings,
                                              :edit_class_timings,
                                              :update_class_timings,
                                              :delete_class_timings,
                                              :new_batch_class_timing_set,
                                              :list_batches,
                                              :add_batch,
                                              :remove_batch
                                          ]
    has_permission_on [:event],
                      :to => [
                          :index,
                          :event_group,
                          :select_course,
                          :course_event,
                          :remove_batch,
                          :select_employee_department,
                          :department_event,
                          :remove_department,
                          :show,
                          :confirm_event,
                          :cancel_event,
                          :edit_event,
                          :new,
                          :create,
                          :update
                      ]
    has_permission_on [:academic_year],
                      :to => [
                          :index,
                          :add_course,
                          :migrate_classes,
                          :migrate_students,
                          :list_students,
                          :update_courses,
                          :upcoming_exams]
    has_permission_on [:attendances],
      :to => [
      :index,
      :show,
      :new,
      :create,
      :edit,
      :destroy,
      :list_subject,
      :update,
      :subject_wise_register,
      :daily_register,
      :quick_attendance,
      :notification_status,
      :list_subjects,
      :send_sms_for_absentees,
      :attendance_register_csv,
      :attendance_register_pdf,
      :save_attendance,
      :lock_attendance,
      :unlock_attendance
    ]
    has_permission_on [:attendance_labels],
      :to => [:index, :create,:new, :show, :make_configuration, :edit, :delete_label, :update]
    has_permission_on [:sms],  :to => [:index, :settings,:update_general_sms_settings, :show_sms_messages, :birthday_sms, :send_sms]
    has_permission_on [:sms],
                      :to => [:students, :list_students, :batches, :sms_all, :employees, :list_employees, :departments, :all, :show_sms_logs, :user_type_selection, :load_student_sms_send, :birthday_sms ] do
      if_attribute :is_enabled => is { true }
    end
    has_permission_on [:sms_settings], :to => [:index, :update_general_sms_settings]
    has_permission_on [:class_timings], :to => [:index, :edit, :destroy, :show, :new, :create, :update]
    has_permission_on [:attendance_reports], :to => [:index, :subjectwise_report, :consolidated_report, :subject, :report_columns, :fetch_columns, :mode, :show, :year, :report, :filter, :student_details, :report_pdf, :filter_report_pdf]
    has_permission_on [:student_attendance], :to => [:index, :student, :leaves_report, :month, :student_report]
    has_permission_on [:configuration], :to => [:index, :settings, :permissions, :add_weekly_holidays, :delete]
    has_permission_on [:custom_words], :to => [:index, :create]
    has_permission_on [:single_access_tokens], :to => [:index, :new, :create, :destroy]
    has_permission_on [:subjects], :to => [:edit_elective_group, :update_batch_list, :load_subject_list, :set_elective_group_name, :index, :new, :create, :destroy, :edit, :update, :show, :destroy_elective_group, :import_subjects, :enable_elective_group_delete,  :delete_component, :edit_component, :update_component]
    has_permission_on [:elective_groups], :to => [:index, :new, :create, :destroy, :edit, :update, :show, :new_elective_subject, :create_elective_subject, :edit_elective_subject, :update_elective_subject]
    has_permission_on [:revert_batch_transfers], :to => [:index, :list_students, :revert_transfer]
    has_permission_on [:courses],
                      :to => [
                          :index,
                          :assign_subject_amount,
                          :edit_subject_amount,
                          :destroy_subject_amount,
                          :manage_course,
                          :manage_batches,
                          :new,
                          :create,
                          :update_batch,
                          :edit,
                          :update,
                          :destroy,
                          :show,
                          :find_course,
                          :grouped_batches,
                          :create_batch_group,
                          :edit_batch_group,
                          :update_batch_group,
                          :delete_batch_group,
                          :inactivate_batch,
                          :activate_batch
                      ]
    has_permission_on [:batches],
                      :to => [
                          :index,
                          :new,
                          :create,
                          :edit,
                          :update,
                          :destroy,
                          :show,
                          :init_data,
                          :assign_tutor,
                          :update_employees,
                          :assign_employee,
                          :remove_employee,
                          :batches_ajax,
                          :batch_summary,
                          :list_batches,
                          :tab_menu_items,
                          :get_tutors,
                          :get_batch_span
                      ]
    has_permission_on [:batch_transfers],
                      :to => [
                          :index,
                          :show,
                          :transfer,
                          :graduation,
                          :subject_transfer,
                          :get_previous_batch_subjects,
                          :update_batch,
                          :assign_previous_batch_subject,
                          :assign_all_previous_batch_subjects,
                          :new_subject,
                          :create_subject,
                          :attendance_transfer
                      ]
    has_permission_on [:employee_attendance],
                      :to => [
                          :add_leave_types,
                          :list_leave_types,
                          :edit_leave_types,
                          :delete_leave_types,
                          :register,
                          :update_attendance_form,
                          :report,
                          :leave_balance_report,
                          :report_pdf,
                          :filter_attendance_report,
                          :update_filterd_attendance_report,
                          :update_attendance_report,
                          :view_attendance,
                          :validate_leave_application,
                          :leave_application,
                          :leave_app,
                          :approve_or_deny_leave,
                          :cancel,
                          :individual_leave_applications,
                          :own_leave_application,
                          :cancel_application,
                          :employee_attendance_pdf,
                          :update_all_application_view,
                          :employee_leave_reset_all,
                          :reset_all_employees,
                          :reset_by_leave_groups,
                          :reset_by_leave_groups_modal,
                          :update_employee_leave_reset_all,
                          :list_department_leave_reset,
                          :update_department_leave_reset,
                          :employee_search_ajax_reset,
                          :employees_list,
                          :employee_leave_details,
                          :employee_wise_leave_reset,
                          :additional_leave_detailed,
                          :additional_leave_detailed_pdf,
                          :additional_leave_report_pdf,
                          :additional_leave_detailed_report_pdf,
                          :settings,
                          :reset_logs,
                          :reset_leaves,
                          :reset_all,
                          :reset_employee_leaves,
                          :employee_reset_logs,
                          :list_failed_employees,
                          :retry_leave_creation,
                          :retry_reset,
                          :retry_employee_reset,
                          :leave_applications,
                          :credit_logs,
                          :credit_leaves,
                          :credit_employee_search_ajax,
                          :list_department_leave_credit,
                          :credit_all,
                          :credit_by_leave_groups,
                          :credit_all_employees,
                          :employee_credit_logs,
                          :credit_by_leave_groups_modal
                      ]

    has_permission_on [:employee_attendance],
                      :to => [
                          :employee_leaves,
                          :my_leave_applications,
                          :leaves
                      ], :join_by => :and do
      if_attribute :id => is { user.id }
      if_attribute :is_employee => true
    end


    has_permission_on [:employee_attendance],
                      :to => [
                          :my_leaves] do
      if_attribute :is_employee => true
    end

    has_permission_on :leave_groups,
                      :to => [
                          :index,
                          :new,
                          :create,
                          :edit,
                          :update,
                          :show,
                          :delete_group,
                          :add_leave_types,
                          :add_employees,
                          :manage_employees,
                          :remove_leave_type,
                          :save_employees,
                          :advanced_search,
                          :remove_employee,
                          :add_individual_leave_type,
                          :manage_leave_group,
                          :leave_group_details
                      ]

    has_permission_on [:employee],
                      :to => [
                          :leaves
                      ] do
      if_attribute :id => is { user.id }
    end
    has_permission_on [:leave_years], :to => [
                                           :index,
                                           :new,
                                           :create,
                                           :edit,
                                           :update,
                                           :set_active,
                                           :leave_process,
                                           :update_active,
                                           :fetch_details,
                                           :delete_year,
                                           :autocredit_setting,
                                           :settings,
                                           :process_leaves,
                                           :leave_records,
                                           :end_year_process_detail,
                                           :retry_employee_reset,
                                           :retry_reset,
                                           :leave_record_filter,
                                           :reset_setting,
                                           :leave_reset_settings,
                                           :confirmation_box,
                                           :credit_date_setting,
                                           :leave_credit_date_settings,
                                           :leave_process_settings,
                                           
                                           
                                       ]

    has_permission_on [:employee_attendance],
                      :to => [
                          :pending_leave_applications
                      ], :join_by => :and do
      if_attribute :pending_applications => true
      if_attribute :manager => true
      if_attribute :id => is { user.id }
    end

    has_permission_on [:employee_attendance],
                      :to => [
                          :reportees_leave_applications,
                          :reportees_leaves
                      ], :join_by => :and do
      if_attribute :manager => true
      if_attribute :id => is { user.id }
    end

    has_permission_on [:employee_attendances],
                      :to => [
                          :index,
                          :show,
                          :new,
                          :create,
                          :edit,
                          :update,
                          :destroy
                      ]
    has_permission_on [:grading_levels],
                      :to => [
                          :index,
                          :show,
                          :edit,
                          :update,
                          :new,
                          :create,
                          :destroy

                      ]
    has_permission_on [:ranking_levels],
                      :to => [
                          :index,
                          :load_ranking_levels,
                          :create_ranking_level,
                          :edit_ranking_level,
                          :update_ranking_level,
                          :delete_ranking_level,
                          :ranking_level_cancel,
                          :change_priority
                      ]
    has_permission_on [:class_designations],
                      :to => [
                          :index,
                          :load_class_designations,
                          :create_class_designation,
                          :edit_class_designation,
                          :update_class_designation,
                          :delete_class_designation
                      ]
    has_permission_on [:course_exam_groups],
                      :to => [
                          :index,
                          :show,
                          :create,
                          :new,
                          :edit,
                          :new_batches,
                          :add_exams,
                          :list_tabs,
                          :list_exam_batches,
                          :list_batches,
                          :update,
                          :list_exam_groups,
                          :update_course_exam_group,
                          :add_batches,
                          :update_imported_exams,
                          :batch_wise_exam_groups,
                          :common_exam_groups
                      ]
    has_permission_on [:exam],
                      :to => [
                          :index,
                          :update_exam_form,
                          :publish,
                          :grouping,
                          :exam_wise_report,
                          :list_exam_types,
                          :generated_report,
                          :generated_report_pdf,
                          :consolidated_exam_report,
                          :consolidated_exam_report_pdf,
                          :subject_wise_report,
                          :subject_rank,
                          :course_rank,
                          :batch_groups,
                          :student_course_rank,
                          :student_course_rank_pdf,
                          :student_school_rank,
                          :student_school_rank_pdf,
                          :attendance_rank,
                          :student_attendance_rank,
                          :student_attendance_rank_pdf,
                          :generate_reports,
                          :generate_previous_reports,
                          :select_inactive_batches,
                          :settings,
                          :report_center,
                          :gpa_cwa_reports,
                          :list_batch_groups,
                          :ranking_level_report,
                          :student_ranking_level_report,
                          :student_ranking_level_report_pdf,
                          :transcript,
                          :student_transcript,
                          :student_transcript_pdf,
                          :combined_report,
                          :load_levels,
                          :student_combined_report,
                          :student_combined_report_pdf,
                          :load_batch_students,
                          :select_mode,
                          :select_batch_group,
                          :select_type,
                          :select_report_type,
                          :batch_rank,
                          :student_batch_rank,
                          :student_batch_rank_pdf,
                          :student_subject_rank,
                          :student_subject_rank_pdf,
                          :list_subjects,
                          :list_batch_subjects,
                          :generated_report2,
                          :generated_report2_pdf,
                          :generated_report3,
                          :final_report_type,
                          :generated_report4,
                          :generated_report4_pdf,
                          :combined_grouped_exam_report_pdf,
                          :previous_years_marks_overview,
                          :previous_years_marks_overview_pdf,
                          :academic_report,
                          :previous_batch_exams,
                          :course_wise_exams,
                          :create_course_wise_exam_group,
                          :update_exam_form_with_multibatch,
                          :list_exam_groups,
                          :update_batch_in_course_wise_exams,
                          :list_inactive_batches,
                          :list_inactive_exam_groups,
                          :previous_exam_marks,
                          :edit_previous_marks,
                          :update_previous_marks,
                          #      :create_exam,
                          :update_batch_ex_result,
                          :update_batch,
                          :graph_for_generated_report,
                          :graph_for_generated_report3,
                          :graph_for_previous_years_marks_overview,
                          :grouped_exam_report,
                          :student_wise_generated_report,
                          :report_settings,
                          :get_normal_report_header_info,
                          :get_report_signature_info,
                          :preview,
                          :students_sorting,
                          :save_sorting_method,
                          :transcript_settings,
                          :transcript_setting_for_course,
                          :save_transcript_setting
                      ]

    has_permission_on [:exam],
                      :to => [
                          :gpa_settings,
                          :cgpa_average_example,
                          :cgpa_credit_hours_example
                      ] do
      if_attribute :gpa_enabled? => is { true }
    end

    has_permission_on [:remarks],
                      :to => [
                          :index,
                          :add_remarks,
                          :create_remarks,
                          :edit_remarks,
                          :edit_common_remarks,
                          :show_remarks,
                          :update_remarks,
                          :update_common_remarks,
                          :destroy_common_remarks,
                          :show_common_remarks,
                          :add_custom_remarks,
                          :create_custom_remarks,
                          :custom_remark_list,
                          :list_custom_remarks,
                          :edit_custom_remarks,
                          :update_custom_remarks,
                          :destroy_custom_remarks,
                          :remarks_history,
                          :add_employee_custom_remarks,
                          :list_student_with_remark_subject,
                          :employee_custom_remark_update,
                          :employee_list_custom_remarks,
                          :list_students,
                          :destroy,
                          :list_batches,
                          :list_specific_batches,
                          :remarks_pdf,
                          :remarks_csv
                      ]
    has_permission_on [:scheduled_jobs],
                      :to => [
                          :index
                      ]
    has_permission_on [:exam_groups],
                      :to => [
                          :index,
                          :new,
                          :create,
                          :edit,
                          :update,
                          :destroy,
                          :show,
                          :initial_queries,
                          :set_exam_minimum_marks,
                          :set_exam_maximum_marks,
                          :set_exam_weightage,
                          :set_exam_group_name,
                          :subject_list,
                          :fa_group_result_publish,
                          :sent_resend_fa_group_publish_sms
                      ]
    has_permission_on [:exams],
                      :to => [
                          :index,
                          :show,
                          :new,
                          :add_new_exams,
                          :create,
                          :edit,
                          :update,
                          :destroy,
                          :save_scores,
                          :query_data
                      ]

    #    has_permission_on [:additional_exam],
    #      :to => [
    #      :index,
    #      :update_exam_form,
    #      :publish,
    #      :create_additional_exam,
    #      :update_batch
    #    ]

    #    has_permission_on [:additional_exam_groups],
    #      :to => [
    #      :index,
    #      :new,
    #      :create,
    #      :edit,
    #      :update,
    #      :destroy,
    #      :show,
    #      :initial_queries,
    #      :set_additional_exam_minimum_marks,
    #      :set_additional_exam_maximum_marks,
    #      :set_additional_exam_weightage,
    #      :set_additional_exam_group_name
    #    ]
    #    has_permission_on [:additional_exams],
    #      :to => [
    #      :index,
    #      :show,
    #      :new,
    #      :create,
    #      :edit,
    #      :update,
    #      :destroy,
    #      :save_additional_scores,
    #      :query_data
    #    ]


    #     has_permission_on [:finance],
    #       :to => [
    #       :index,
    #       :automatic_transactions,
    #       :categories,
    #       :donation,
    #       :donation_receipt,
    #       :expense_create,
    #       :expense_edit,
    #       :fee_collection,
    #       :fee_submission,
    #       :fees_received,
    #       :fee_structure,
    #       :fees_student_specific,
    #       :income_create,
    #       :transactions,
    #       :category_create,
    #       :category_delete,
    #       :category_edit,
    #       :category_update,
    #       :get_child_fee_element_form,
    #       :get_new_fee_element_form,
    #       :create_child_fee_element,
    #       :create_new_fee_element,
    #       :reset_fee_element,
    #       :fee_collection_create,
    #       :fee_collection_delete,
    #       :fee_collection_edit,
    #       :fee_collection_update,
    #       :fee_structure_create,
    #       :fee_structure_delete,
    #       :fee_structure_edit,
    #       :fee_structure_update,
    #       :transaction_trigger_create,
    #       :transaction_trigger_edit,
    #       :transaction_trigger_update,
    #       :transaction_trigger_delete,
    #       :fees_student_search,
    #       :search_logic,
    #       :fees_received,
    #       :fees_defaulters,
    #       :fees_submission_index,
    #       :fees_submission_batch,
    #       :update_fees_collection_dates,
    #       :load_fees_submission_batch,
    #       :update_ajax,
    #       :update_batches,
    #       :update_fees_collection_dates_defaulters,
    #       :fees_defaulters_students,
    #       :monthly_report,
    #       :update_monthly_report,
    #       :year_report,
    #       :update_year_report,
    #       :approve_monthly_payslip,
    #       :one_click_approve_submit,
    #       :one_click_approve,
    #       :employee_payslip_approve,
    #       :employee_payslip_reject,
    #       :employee_payslip_accept_form,
    #       :employee_payslip_reject_form,
    #       :payslip_index,
    #       :view_monthly_payslip,
    #       :view_monthly_payslip_search,
    #       :view_monthly_payslip_pdf,
    #       :update_monthly_payslip,:search_ajax,
    #       :view_payslip_dept,
    #       :update_dates,
    #       :update_monthly_payslip_all,
    #       :fee_structure_select_batch,
    #       :fees_student_dates,
    #       :fee_structure_batch,
    #       :fees_structure_student_search,
    #       :search_fees_structure,
    #       :fees_structure_dates,
    #       :fees_structure_result,
    #       :salary_department,
    #       :salary_employee,
    #       :employee_payslip_monthly_report,
    #       :direct_expenses,
    #       :direct_income,
    #       :donations_report,
    #       :fees_report,
    #       :batch_fees_report,
    #       :salary_department_year,
    #       :salary_employee_year,
    #       :direct_expenses_year,
    #       :direct_income_year,
    #       :donations_report_year,
    #       :fees_report_year,
    #       :asset_liability,
    #       :liability,
    #       :create_liability,
    #       :view_liability,
    #       :each_liability_view,
    #       :asset,
    #       :create_asset,
    #       :view_asset,
    #       :each_asset_view,
    #       :edit_liability,
    #       :update_liability,
    #       :delete_liability,
    #       :edit_asset,
    #       :update_asset,
    #       :delete_asset,
    #       :fee_collection_view,
    #       :fee_collection_dates_batch,
    #       :pay_fees_defaulters,
    #       :fee_structure_fee_collection_date,
    #       :fees_student_specific_dates,
    #       :update_fees_specific,
    #       :fees_index,
    #       #new_fee-----------
    #       :master_fees,
    #       :show_master_categories_list,
    #       #      :show_additional_fees_list,
    #       :fees_particulars,
    #       #      :additional_fees,
    #       #      :additional_fees_create_form,
    #       #      :additional_fees_create,
    #       #      :additional_fees_view,
    #       :add_particulars,
    #       :fee_collection_batch_update,
    #       :fees_submission_student,
    #       :fees_submission_save,
    #       :fee_particulars_update,
    #       :student_or_student_category,
    #       :fees_student_structure_search,
    #       :fees_student_structure_search_logic,
    #       :fee_structure_dates,
    #       :fees_structure_for_student,
    #       :master_fees_index,
    #       :master_category_create,
    #       :master_category_new,
    #       :fees_particulars_new,
    #       :fees_particulars_new2,
    #       :fees_particulars_create,
    #       :fees_particulars_create2,
    #       :add_particulars_new,
    #       :add_particulars_create,
    #       :fee_discounts,
    #       :fee_discount_new,
    #       :load_discount_create_form,
    #       :load_discount_batch,
    #       :load_batch_fee_category,
    #       :batch_wise_discount_create,
    #       :category_wise_fee_discount_create,
    #       :student_wise_fee_discount_create,
    #       :update_master_fee_category_list,
    #       :show_fee_discounts,
    #       :edit_fee_discount,
    #       :update_fee_discount,
    #       :delete_fee_discount,
    #       :fee_collection_new,
    #       :collection_details_view,
    #       :fee_collection_create,
    #       :categories_new,
    #       :categories_create,
    #       :master_category_edit,
    #       :master_category_update,
    #       :master_category_delete,
    #       :master_category_particulars,
    #       :master_category_particulars_edit,
    #       :master_category_particulars_update,
    #       :master_category_particulars_delete,
    #       #      :additional_fees_list,
    #       :additional_particulars,
    #       :add_particulars_edit,
    #       :add_particulars_update,
    #       :add_particulars_delete,
    #       #      :additional_fees_edit,
    #       #      :additional_fees_update,
    #       #      :additional_fees_delete,
    #       :month_date,
    #       :compare_report,
    #       :report_compare,
    #       :graph_for_compare_monthly_report,
    #       :update_fine_ajax,
    #       :student_fee_receipt_pdf,
    #       :update_student_fine_ajax,
    #       :transaction_pdf,
    #       :update_defaulters_fine_ajax,
    #       :fee_defaulters_pdf,
    #       :donation_receipt_pdf,
    #       :donors,
    #       :expense_list,
    #       :expense_list_update,
    #       :income_list,
    #       :income_list_update,
    # #      :income_details,
    # #      :income_details_pdf,
    #       :partial_payment,
    #       :donation_edit,
    #       :donation_delete,
    #       #pdf-------------
    #       :pdf_fee_structure,
    #
    #       #graph-------------
    #       :graph_for_update_monthly_report,
    #
    #       :view_employee_payslip,
    #       :income_list_pdf,
    #       :expense_list_pdf,
    #       :asset_pdf,
    #       :liability_pdf,
    #       :income_edit,
    #       :delete_transaction,
    #       :select_payment_mode,
    #       :delete_transaction_by_batch,
    #       :delete_transaction_for_student,
    #       :transaction_deletion,
    #       :delete_transaction_fees_defaulters,
    #       :deleted_transactions,
    #       :update_deleted_transactions,
    #       :list_deleted_transactions,
    #       :search_fee_collection,
    #       :transaction_filter_by_date,
    #       :transactions_advanced_search,
    #       :list_category_batch,
    #       :fees_refund,
    #       :create_refund,
    #       :new_refund,
    #       :apply_refund,
    #       :refund_student_search,
    #       :fees_refund_dates,
    #       :fees_refund_student,
    #       :view_refunds,
    #       :refund_filter_by_date,
    #       :search_fee_refunds,
    #       :list_refunds,
    #       :fee_refund_student_pdf,
    #       :refund_search_pdf,
    #       :generate_fine,
    #       :new_fine,
    #       :fine_list,
    #       :add_fine_slab,
    #       :fine_slabs_edit_or_create,
    #       :finance_reports,
    #       :fee_category_particulars,
    #       :particular_batches,
    #       :student_category_particulars,
    #       :category_particulars,
    #       :student_particulars,
    #       :refund_student_view,
    #       :refund_student_view_pdf,
    #       :delete_transaction_for_particular_wise_fee_pay,
    #       :student_wise_fee_payment,
    #     ]
    #     has_permission_on [:finance_extensions],:to=>[
    #       :pay_all_fees,
    #       :delete_multi_fees_transaction,
    #       :pay_all_fees_receipt_pdf,
    #       :pay_fees_in_particular_wise,
    #       :particular_wise_fee_payment,
    #       :particular_wise_fee_pay_pdf
    #     ]

    has_permission_on [:xml], :to =>
                                [
                                    :create_xml,
                                    :index,
                                    :settings,
                                    :download
                                ]

    has_permission_on [:holiday], :to => [:index, :edit, :delete]
    has_permission_on [:news],
                      :to => [
                          :index,
                          :load_news,
                          :show_pending_comments,
                          :show_approved_comments,
                          :load_comments,
                          :reset_news,
                          :add,
                          :add_comment,
                          :all,
                          :delete,
                          :delete_comment,
                          :approve_comment,
                          :edit,
                          :update,
                          :new,
                          :create,
                          :search_news_ajax,
                          :view,
                          :show,
                          :comment_view]

    has_permission_on [:student],
                      :to => [
                          :academic_pdf,
                          :profile,
                          :admission1,
                          :render_batch_list,
                          :set_roll_number_prefix,
                          :admission1_2,
                          :admission2,
                          :admission3,
                          :add_guardian,
                          :edit,
                          :edit_guardian,
                          :guardians,
                          :del_guardian,
                          :list_students_by_course,
                          :show,
                          :view_all,
                          :index,
                          :academic_report,
                          :academic_report_all,
                          :change_to_former,
                          :delete,
                          :destroy,
                          :exam_report,
                          :update_student_result_for_examtype,
                          :previous_years_marks_overview,
                          :previous_years_marks_overview_pdf,
                          :remove,
                          :reports,
                          :search_ajax,
                          :student_annual_overview,
                          :subject_wise_report,
                          :graph_for_previous_years_marks_overview,
                          :graph_for_academic_report,
                          :graph_for_annual_academic_report,
                          :graph_for_student_annual_overview,
                          :graph_for_subject_wise_report_for_one_subject,
                          :graph_for_exam_report,
                          :category_update,
                          :category_edit,
                          :category_delete,
                          :categories,
                          :add_additional_details,
                          :change_field_priority,
                          :edit_additional_details,
                          :delete_additional_details,
                          :admission4,
                          :advanced_search,
                          :list_batches,
                          :electives,
                          :assigned_elective_subjects,
                          :search_students,
                          :assign_students,
                          :unassign_students,
                          :list_doa_year,
                          :doa_equal_to_update,
                          :doa_less_than_update,
                          :doa_greater_than_update,
                          :list_dob_year, :dob_equal_to_update, :dob_less_than_update, :dob_greater_than_update,
                          :advanced_search_pdf,
                          :previous_data,
                          :previous_data_from_profile,
                          :previous_subject,
                          :previous_data_edit,
                          :save_previous_subject,
                          :delete_previous_subject,
                          :profile_pdf,
                          :generate_tc_pdf,
                          :generate_all_tc_pdf,
                          :assign_all_students,
                          :unassign_all_students,
                          :edit_admission4,
                          :admission3_1,
                          :admission3_2,
                          :show_previous_details,
                          :fees,
                          :fee_details,
                          :my_subjects,
                          :choose_elective,
                          :remove_elective,
                          :activities,
                          :update_activities,
                          :destroy_dependencies,
                          :pay_all_fees_index,
                          :student_search_autocomplete,
                          :list_students_by_batch,
                          :search_students_for_pay_all_fees,
                          :pay_all_fees,
                          :view_all_fees,
                          :delete_multi_fees_transaction,
                          :delete_transaction_for_particular_wise_fee_pay,
                          :pay_all_fees_receipt_pdf,
                          :student_fees_preference,
                          :unlink_sibling
                      ]
    has_permission_on [:finance_extensions], :to => [
                                               :search_students_for_pay_all_fees,
                                               :pay_all_fees_index,
                                               :student_search_autocomplete,
                                               :list_students_by_batch,
                                               :pay_all_fees,
                                               :delete_multi_fees_transaction,
                                               :pay_all_fees_receipt_pdf,
                                               :pay_fees_in_particular_wise,
                                               :particular_wise_fee_payment,
                                               :particular_wise_fee_pay_pdf,
                                               :fetch_waiver_amount_pay_all,
                                               :fetch_waiver_amount_collection_wise,
                                               :fetch_total_fine_amount_for_pay_all
                                               
                                           ]
    has_permission_on [:archived_student],
                      :to => [
                          :profile,
                          :reports,
                          :guardians,
                          :delete,
                          :destroy,
                          :generate_tc_pdf,
                          :consolidated_exam_report,
                          :consolidated_exam_report_pdf,
                          :academic_report,
                          :student_report,
                          :generated_report,
                          :generated_report_pdf,
                          :generated_report3,
                          :previous_years_marks_overview,
                          :previous_years_marks_overview_pdf,
                          :generated_report4,
                          :generated_report4_pdf,
                          :graph_for_generated_report,
                          :graph_for_generated_report3,
                          :graph_for_previous_years_marks_overview,
                          :edit_leaving_date,
                          :revert_archived_student,
                          :fees
                      ]
    has_permission_on [:subject],
                      :to => [
                          :index,
                          :create,
                          :delete,
                          :edit,
                          :list_subjects]
    has_permission_on [:timetable],
                      :to => [:index,
                              :new_timetable,
                              :update_timetable,
                              :manage_batches,
                              :manage_timetables,
                              :manage_allocations,
                              :manage_work_allocations,
                              :load_manage_subject,
                              :load_work_allocations,
                              :update_employee_list,
                              :update_batch_list,
                              :assign_employee,
                              :remove_employee,
                              :summary,
                              :update_summary,
                              :batch_subject_utilization,
                              :employees_hour_utilization,
                              :batch_allocation_list,
                              :employee_hour_overlaps,
                              :load_batch_wise_summary,
                              :update_course_work_allotment,
                              :add_batch_timetable,
                              :remove_batch_timetable,
                              :view,
                              :edit_master,
                              :teachers_timetable,
                              :update_employee_timetable,
                              :update_teacher_tt,
                              :update_timetable_view,
                              :timetable_view_batches,
                              :destroy,
                              :employee_timetable,
                              :employee_timetable_pdf,
                              :update_employee_tt,
                              :student_view,
                              :update_student_tt,
                              :weekdays,
                              :settings,
                              :timetable,
                              :timetable_pdf,
                              :work_allotment,
                              :csv_reports,
                              :csv_report_download,
                              :pdf_reports, 
                              :pdf_report_download
                      ]
    has_permission_on [:timetable_entries],
                      :to => [
                          :new,
                          :select_batch,
                          :new_entry,
                          :update_employees,
                          :delete_employee2,
                          :update_multiple_timetable_entries2,
                          :tt_entry_update2,
                          :tt_entry_noupdate2,
                          :update_batch_list
                      ]
    has_permission_on [:weekdays],
                      :to => [
                          :index,
                          :new
                      ]
    has_permission_on [:archived_employee],
                      :to => [
                          :profile,
                          :profile_general,
                          :profile_personal,
                          :profile_address,
                          :profile_contact,
                          :profile_bank_details,
                          :profile_additional_details,
                          :profile_payroll_details,
                          :profile_pdf,
                          :show,
                          :change_to_present
                      ]
    has_permission_on [:employee],
                      :to => [
                          :index,
                          :add_category,
                          :edit_category,
                          :delete_category,
                          :add_position,
                          :edit_position,
                          :delete_position,
                          :add_department,
                          :edit_department,
                          :delete_department,
                          :add_grade,
                          :edit_grade,
                          :delete_grade,
                          :admission1,
                          :update_positions,
                          :edit1,
                          :edit_leave_balance,
                          :add_individual_leave,
                          :remove_individual_leave,
                          :edit_personal,
                          :admission2,
                          :edit2,
                          :edit_contact,
                          :admission3,
                          :edit3,
                          :admission4,
                          :change_reporting_manager,
                          :reporting_manager_search,
                          :update_reporting_manager_name,
                          :edit4,
                          :search,
                          :search_ajax,
                          :select_reporting_manager,
                          :profile,
                          :profile_general,
                          :profile_personal,
                          :profile_address,
                          :profile_contact,
                          :profile_bank_details,
                          :profile_payroll_details,
                          :view_all,
                          :show,
                          :view_payslip,
                          :update_monthly_payslip,
                          :view_attendance,
                          :subject_assignment,
                          :update_subjects,
                          :select_department,
                          :update_employees,
                          :assign_employee,
                          :remove_employee,
                          :hr,
                          :payroll_and_payslips,
                          :payslip,
                          :leave_management,
                          :update_employees_select,
                          :leave_list,
                          :settings,
                          :employee_management,
                          :employee_attendance,
                          :employees_list,
                          :add_bank_details,
                          :edit_bank_details,
                          :delete_bank_details,
                          :admission3,
                          :admission3_1,
                          :admission3_2,
                          :add_additional_details,
                          :change_field_priority,
                          :edit_additional_details,
                          :delete_additional_details,
                          :profile_additional_details,
                          :edit3_1,
                          :advanced_search,
                          :list_doj_year,
                          :doj_equal_to_update,
                          :doj_less_than_update,
                          :doj_greater_than_update,
                          :list_dob_year, :dob_equal_to_update, :dob_less_than_update, :dob_greater_than_update,
                          :remove, :change_to_former, :delete, :remove_subordinate_employee,
                          :edit_privilege,
                          :advanced_search_pdf,
                          :profile_pdf,
                          :view_rep_manager,
                          :employee_leave_count_edit,
                          :employee_leave_count_update,
                          :activities,
                          :update_activities

                      ]
    has_permission_on [:calendar], :to => [:event_delete]

    has_permission_on [:descriptive_indicators],
                      :to => [
                          :index,
                          :new,
                          :create,
                          :show,
                          :edit,
                          :update,
                          :destroy,
                          :reorder,
                          :destroy_indicator,
                          :show_in_report,
                          :add_observation_remark,
                          :create_observation_remark,
                          :edit_observation_remark,
                          :update_observation_remark,
                          :destroy_observation_remark
                      ], :join_by => :and do
      if_attribute :assess_truth => is { user.cce_enabled? }
    end
    has_permission_on [:fa_criterias],
                      :to => [
                          :index,
                          :show
                      ], :join_by => :and do
      if_attribute :assess_truth => is { user.cce_enabled? }
    end
    has_permission_on [:fa_groups],
                      :to => [
                          :index,
                          :new,
                          :create,
                          :edit,
                          :update,
                          :destroy,
                          :show,
                          :assign_fa_groups,
                          :select_subjects,
                          :select_fa_groups,
                          :update_subject_fa_groups,
                          :new_fa_criteria,
                          :create_fa_criteria,
                          :edit_fa_criteria,
                          :update_fa_criteria,
                          :destroy_fa_criteria,
                          :reorder,
                          :edit_criteria_formula,
                          :update_criteria_formula,
                          :formula_examples

                      ], :join_by => :and do
      if_attribute :assess_truth => is { user.cce_enabled? }
    end
    has_permission_on [:observation_groups],
                      :to => [
                          :index,
                          :new,
                          :show,
                          :create,
                          :edit,
                          :update,
                          :destroy,
                          :new_observation,
                          :edit_observation,
                          :create_observation,
                          :edit_osbervation,
                          :update_observation,
                          :destroy_observation,
                          :assign_courses,
                          :select_observation_groups,
                          :update_course_obs_groups,
                          :reorder,
                          :reorder_ob_groups
                      ], :join_by => :and do
      if_attribute :assess_truth => is { user.cce_enabled? }
    end
    has_permission_on [:observation_remarks],
                      :to => [
                          :new,
                          :create,
                          :edit,
                          :update,
                          :destroy,
                          :co_scholastic_remark_settings,
                          :get_di_info,
                      ], :join_by => :and do
      if_attribute :assess_truth => is { user.cce_enabled? }
    end
    has_permission_on [:observations],
                      :to => [
                          :show
                      ], :join_by => :and do
      if_attribute :assess_truth => is { user.cce_enabled? }
    end
    has_permission_on [:assessment_scores],
                      :to => [
                          :fa_scores,
                          :observation_groups,
                          :observation_scores,
                          :get_grade,
                          :search_batch_students,
                          :get_fa_groups,
                          :scores_form
                      ], :join_by => :and do
      if_attribute :assess_truth => is { user.cce_enabled? }
    end
    has_permission_on [:asl_scores],
                      :to => [
                          :show,
                          :save_scores
                      ], :join_by => :and do
      if_attribute :assess_truth => is { user.cce_enabled? }
    end
    has_permission_on [:cce_exam_categories],
                      :to => [
                          :index,
                          :new,
                          :show,
                          :create,
                          :edit,
                          :update,
                          :destroy
                      ], :join_by => :and do
      if_attribute :assess_truth => is { user.cce_enabled? }
    end
    has_permission_on [:cce_grade_sets],
                      :to => [
                          :index,
                          :new,
                          :create,
                          :edit,
                          :update,
                          :destroy,
                          :show,
                          :index,
                          :new_grade,
                          :create_grade,
                          :edit_grade,
                          :update_grade,
                          :destroy_grade
                      ], :join_by => :and do
      if_attribute :assess_truth => is { user.cce_enabled? }
    end
    has_permission_on [:cce_reports],
                      :to => [
                          :index,
                          :create_reports,
                          :student_wise_report,
                          :generate_student_wise_report,
                          :student_report_pdf,
                          :student_transcript,
                          :student_report,
                          :consolidated_report,
                          :detailed_fa_report,
                          :detailed_fa_batches,
                          :detailed_fa_list_subjects,
                          :detailed_fa_list_fa_groups,
                          :generated_detailed_fa_report,
                          :generated_detailed_fa_report_csv,
                          :list_batches,
                          :update_assessment_groups,
                          :generated_report,
                          :generated_report_csv,
                          :generated_report_pdf,
                          :subject_wise_report,
                          :subject_wise_batches,
                          :list_subjects,
                          :subject_wise_generated_report,
                          :subject_wise_generated_report_csv,
                          :subject_wise_generated_report_pdf,
                          :list_exam_groups,
                          :list_asl_groups,
                          :asl_report_csv,
                          :set_assessment_group,
                          :full_report_pdf,
                          :cbse_report,
                          :asl_report,
                          :generate_asl_report,
                          :upscale_report,
                          :cbse_scholastic_report,
                          :cbse_co_scholastic_report,
                          :generate_cbse_scholastic_report,
                          :list_observation_groups,
                          :generate_cbse_co_scholastic_report,
                          :generate_cbse_scholastic_report_csv,
                          :cce_full_exam_report,
                          :generate_cbse_co_scholastic_report_csv,
                          :batch_student_report,
                          :new_batch_wise_student_report,
                          :generate_batch_student_report,
                          :batch_wise_student_report_download,
                          :get_batches,
                          :get_students_list,
                          :previous_batch_exam_reports,
                          :list_previous_batches,
                          :generate_previous_batch_exam_reports,
                          :graph_for_student_report,
                          :student_fa_report_pdf
                      ], :join_by => :and do
      if_attribute :assess_truth => is { user.cce_enabled? }
    end

    has_permission_on [:cce_settings],
                      :to => [
                          :index,
                          :basic,
                          :scholastic,
                          :co_scholastic
                      ], :join_by => :and do
      if_attribute :assess_truth => is { user.cce_enabled? }
    end
    has_permission_on [:cce_settings],
                      :to => [
                          :fa_settings,
                          :fa_total_example,
                          :fa_average_example
                      ], :join_by => :and do
      if_attribute :assess_truth => is { user.cce_enabled? }
    end
    has_permission_on [:cce_report_settings],
                      :to => [
                          :settings,
                          :normal_report_settings,
                          :update_record_lists,
                          :get_report_header_info,
                          :get_additional_fields,
                          :get_normal_report_header_info,
                          :get_report_grading_levels_info,
                          :get_report_signature_info,
                          :unlink,
                          :preview,
                          :normal_preview,
                          :upscale_settings,
                          :upscale_scores,
                          :get_course_batch_selector,
                          :get_batches_list,
                          :get_inactive_batches_list,
                          :cancel,
                          :save_upscale_scores,
                          :cbse_co_scholastic_settings,
                          :get_observations,
                          :save_cbse_co_scholastic_settings,
                          :manage_criteria,
                          :co_scholastic_remarks_settings
                      ], :join_by => :and do
      if_attribute :assess_truth => is { user.cce_enabled? }
    end
    has_permission_on [:cce_weightages],
                      :to => [
                          :index,
                          :new,
                          :create,
                          :show,
                          :edit,
                          :update,
                          :destroy,
                          :assign_courses,
                          :assign_weightages,
                          :select_weightages,
                          :update_course_weightages
                      ], :join_by => :and do
      if_attribute :assess_truth => is { user.cce_enabled? }
    end
    has_permission_on [:classroom_allocations],
                      :to => [
                          :index,
                          :new,
                          :view,
                          :weekly_allocation,
                          :date_specific_allocation,
                          :render_classrooms,
                          :display_rooms,
                          :update_allocation_entries,
                          :override_allocations,
                          :delete_allocation,
                          :find_allocations
                      ]
    has_permission_on [:buildings],
                      :to => [
                          :index,
                          :new,
                          :update,
                          :edit,
                          :show
                      ]
    has_permission_on [:classrooms],
                      :to => [
                          :show
                      ]
    has_permission_on [:icse_settings],
                      :to => [
                          :index,
                          :icse_exam_categories,
                          :new_icse_exam_category,
                          :create_icse_exam_category,
                          :edit_icse_exam_category,
                          :update_icse_exam_category,
                          :destroy_icse_exam_category,
                          :icse_weightages,
                          :new_icse_weightage,
                          :create_icse_weightage,
                          :edit_icse_weightage,
                          :update_icse_weightage,
                          :destroy_icse_weightage,
                          :assign_icse_weightages,
                          :select_subjects,
                          :select_icse_weightages,
                          :update_subject_weightages,
                          :internal_assessment_groups,
                          :new_ia_group,
                          :create_ia_group,
                          :edit_ia_group,
                          :update_ia_group,
                          :destroy_ia_group,
                          :assign_ia_groups,
                          :ia_group_subjects,
                          :select_ia_groups,
                          :update_subject_ia_groups,
                          :ia_settings,
                          :ia_total_example,
                          :ia_average_example

                      ], :join_by => :and do
      if_attribute :assess_truth => is { user.icse_enabled? }
    end
    has_permission_on [:ia_scores],
                      :to => [
                          :ia_scores,
                          :update_ia_score
                      ], :join_by => :and do
      if_attribute :assess_truth => is { user.icse_enabled? }
    end
    has_permission_on [:icse_report_settings],
                      :to => [
                          :settings,
                          :get_report_header_info,
                          :get_report_signature_info,
                          :get_report_grading_levels_info,
                          :preview
                      ], :join_by => :and do
      if_attribute :assess_truth => is { user.icse_enabled? }
    end
    has_permission_on [:icse_reports],
                      :to => [
                          :index,
                          :generate_reports,
                          :student_wise_report,
                          :generate_student_wise_report,
                          :student_report,
                          :student_report_pdf,
                          :student_transcript,
                          :subject_wise_report,
                          :list_batches,
                          :list_subjects,
                          :list_exam_groups,
                          :subject_wise_generated_report,
                          :internal_and_external_mark_pdf,
                          :detailed_internal_and_external_mark_pdf,
                          :internal_and_external_mark_csv,
                          :detailed_internal_and_external_mark_csv,
                          :consolidated_report,
                          :consolidated_generated_report,
                          :consolidated_report_csv,
                          :student_report_csv,
                          :batches_ajax,
                          :previous_batch_exam_reports,
                          :list_previous_batches,
                          :generate_previous_batch_exam_reports
                      ], :join_by => :and do
      if_attribute :assess_truth => is { user.icse_enabled? }
    end
    has_permission_on [:attendance_reports], :to => [:day_wise_report, :day_wise_report_filter_by_course, :day_wise_report_filter_by_type,:day_wise_report_filter_by_attendance_type, :daily_report_batch_wise] do
      if_attribute :can_view_day_wise_report? => is { true }
    end
    has_permission_on [:payroll_groups], :to => [
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
                                       ]
    has_permission_on [:payroll_categories], :to => [
                                               :index,
                                               :new,
                                               :create,
                                               :edit,
                                               :update,
                                               :destroy,
                                               :show,
                                               :hr_formula_form,
                                               :validate_formula
                                           ]
    has_permission_on [:employee_payslips], :to => [
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
                                          ]
    has_permission_on [:payroll], :to => [
                                    :assigned_employees,
                                    :assign_employees,
                                    :employee_list,
                                    :remove_from_payroll_group,
                                    :create_employee_payroll,
                                    :add_employee_payroll,
                                    :calculate_employee_payroll_components,
                                    :show,
                                    :show_warning,
                                    :manage_payroll,
                                    :settings
                                ]
    includes :manage_hr_reports
  end

  # student- privileges
  role :student do
    includes :open
    # has_permission_on [:user], :to => [:profile,:user_change_password,:my_subjects,:choose_elective, :remove_elective,:dashboard,:logout,:login] do
    has_permission_on [:advance_payment_fees],
                      :to => [
                          :advance_fee_students,
                          :advance_payment_by_student,
                          :list_online_fee_head_form,
                          :initialize_advance_payment,
                          :change_gateway_options,
                          :making_payment,
                          :start_transaction,
                          :advance_fees_receipt_pdf,
                          :online_fees_receipt_pdf,
                          :submit_fees,
                          :payment_history,
                          :check_amount_to_pay,
                          :generate_fee_receipt
                        ]
    has_permission_on [:user], :to => [:profile, :my_subjects, :choose_elective, :remove_elective, :dashboard, :logout, :login] do
      if_attribute :id => is { user.id }
    end
    has_permission_on [:student_records],
                      :to => [
                          :individual_student_records
                      ]
    has_permission_on [:csv_export], :to => [:generate_csv]

    has_permission_on [:reminder], :to => [
                                     #      :reminder,
                                     #      :sent_reminder,
                                     #      :view_sent_reminder,
                                     :delete_reminder_by_sender,
                                     :delete_reminder_by_recipient,
                                     #      :view_reminder,
                                     :mark_unread,
                                     :pull_reminder_form,
                                     :send_reminder,
                                     :reminder_actions,
                                     :sent_reminder_delete,
                                     #      :create_reminder,
                                     :to_employees,
                                     :to_students,
                                     :to_parents,
                                     :update_recipient_list,
                                     :update_recipient_list1,
                                     :update_recipient_list2,
                                     :model_box

                                 ]
    has_permission_on [:course], :to => [:view]
    has_permission_on [:exam], :to => [:student_wise_generated_report, :generated_report, :generated_report4_pdf, :graph_for_generated_report, :academic_report, :previous_years_marks_overview, :previous_years_marks_overview_pdf, :graph_for_previous_years_marks_overview, :generated_report3, :graph_for_generated_report3, :student_transcript, :student_transcript_pdf]
    has_permission_on [:exam],
                      :to => [
                          :generated_report4,
                      ], :join_by => :and do
      if_attribute :is_student_in_this_batch => true
      if_attribute :icse_enabled? => is { false }
      if_attribute :cce_enabled? => is { false }
    end
    has_permission_on [:student],
                      :to => [
                          # :exam_report,
                          # :show,
                          # :academic_pdf,
                          :list_students_by_course,
                          # :academic_report,
                          # :previous_years_marks_overview,
                          # :previous_years_marks_overview_pdf,
                          # :student_annual_overview,
                          :subject_wise_report,
                          # :graph_for_previous_years_marks_overview,
                          # :graph_for_student_annual_overview,
                          # :graph_for_subject_wise_report_for_one_subject,
                          # :graph_for_exam_report,
                          # :graph_for_academic_report,
                          :choose_elective,
                          :remove_elective,
                          :fee_details,
                      ]
    has_permission_on [:student],
                      :to => [
                          :profile,
                          :fees,
                          :guardians,
                          :reports,
                          :activities,
                          :update_activities,
                          :show_previous_details,
                          :my_subjects,
                      ] do
      if_attribute :id => is { user.id }
    end
    has_permission_on [:news],
                      :to => [
                          :index,
                          :all,
                          :search_news_ajax,
                          :view,
                          :show,
                          :comment_view,
                          :add_comment,
                      ]
    has_permission_on [:news],
                      :to => [
                          :delete_comment,
                          :load_news,
                          :load_comments,
                      ] do
      if_attribute :author_id => is { user.id }
    end
    has_permission_on [:subject], :to => [:index, :list_subjects]
    has_permission_on [:timetable], :to => [:student_view, :update_student_tt, :timetable_pdf]
    has_permission_on [:attendance], :to => [:student_report]
    has_permission_on [:student_attendance], :to => [:student, :month, :leaves_report, :student_report]
    has_permission_on [:finance],
                      :to => [
                          :student_fees_structure, :refund_student_view,
                          :refund_student_view_pdf,
                          :generate_fee_receipt_pdf,
                          :generate_fee_receipt_pdf_new
                      ] do
      if_attribute :user_id => is { user.id }
    end
    has_permission_on [:cce_reports],
                      :to => [
                          :student_transcript,
                          :student_report_pdf,
                          :cce_full_exam_report,
                          :student_fa_report_pdf
                      ], :join_by => :and do
      if_attribute :assess_truth => is { user.cce_enabled? }
      if_attribute :id => is { user.id }
    end

    has_permission_on [:icse_reports],
                      :to => [
                          :student_report_pdf,
                          :student_transcript,
                          :student_report_csv
                      ], :join_by => :and do
      if_attribute :assess_truth => is { user.icse_enabled? }
      if_attribute :id => is { user.id }
    end
    has_permission_on [:remarks],
                      :to => [
                          :list_custom_remarks,
                          :show_common_remarks
                      ]
    has_permission_on [:remarks], :to => [
                                    :custom_remark_list,
                                    :remarks_history,
                                    :remarks_pdf,
                                    :remarks_csv
                                ] do
      if_attribute :has_remarks_privilege => is { true }
    end
    has_permission_on [:finance], :to => [
                                    :student_fee_receipt_pdf
                                ] do
      if_attribute :user_id => is { user.id }
    end
    has_permission_on [:finance_extensions], :to => [
                                               :pay_all_fees_receipt_pdf
                                           ] do
      if_attribute :user_id => is { user.id }
    end
    has_permission_on [:finance_extensions], :to => [
                                               :generate_overall_fee_receipt_pdf
                                           ] do
      if_attribute :payee_id => is { user.student_record.id }
    end
    has_permission_on [:student_documents], :to => [:documents] do
      if_attribute :id => is { user.student_record.id }
    end
    has_permission_on [:student_documents], :to => [:download] do
      if_attribute :id => is { user.student_record.id }
    end
    has_permission_on [:assessment_reports], :to => [
                                               :students_term_reports,
                                               :student_term_report_pdf,
                                               :student_exam_reports,
                                               :student_exam_report_pdf,
                                               :students_planner_reports,
                                               :student_plan_report_pdf,
                                               :batch_reports,
                                               :select_report,
                                               :refresh_report
                                           ] do
      if_attribute :id => is { user.student_record.id }
    end
  end

  role :parent do
    includes :open
    # has_permission_on [:user], :to => [:profile,:user_change_password, :my_subjects, :choose_elective, :remove_elective,:dashboard,:logout,:login] do
    has_permission_on [:user], :to => [:profile, :my_subjects, :choose_elective, :remove_elective, :dashboard, :logout, :login] do
      if_attribute :id => is { user.id }
    end
    has_permission_on [:advance_payment_fees],
                      :to => [
                          :advance_fee_students,
                          :advance_payment_by_student,
                          :list_online_fee_head_form,
                          :initialize_advance_payment,
                          :change_gateway_options,
                          :making_payment,
                          :start_transaction,
                          :generate_fee_receipt,
                          :online_fees_receipt_pdf,
                          :advance_fees_receipt_pdf,
                          :payment_history,
                          :check_amount_to_pay
                        ]
    has_permission_on [:student_records],
                      :to => [
                          :individual_student_records
                      ]
    has_permission_on [:csv_export], :to => [:generate_csv]
    has_permission_on [:reminder], :to => [
                                     #      :reminder,
                                     #      :sent_reminder,
                                     #      :view_sent_reminder,
                                     :delete_reminder_by_sender,
                                     :delete_reminder_by_recipient,
                                     #      :view_reminder,
                                     :mark_unread,
                                     :pull_reminder_form,
                                     :send_reminder,
                                     :reminder_actions,
                                     :sent_reminder_delete,
                                     #      :create_reminder,
                                     :to_employees,
                                     :to_students,
                                     :to_parents,
                                     :update_recipient_list,
                                     :update_recipient_list1,
                                     :update_recipient_list2,
                                     :model_box

                                 ]
    has_permission_on [:course], :to => [:view]
    has_permission_on [:exam], :to => [:student_wise_generated_report, :generated_report, :generated_report4_pdf, :graph_for_generated_report, :academic_report, :previous_years_marks_overview, :previous_years_marks_overview_pdf, :graph_for_previous_years_marks_overview, :generated_report3, :graph_for_generated_report3, :generated_report4, :student_transcript, :student_transcript_pdf]
    has_permission_on [:exam],
                      :to => [
                          :generated_report4,
                      ], :join_by => :and do
      if_attribute :is_student_in_this_batch => true
      if_attribute :icse_enabled? => is { false }
      if_attribute :cce_enabled? => is { false }
    end
    has_permission_on [:timetable], :to => [:student_view, :update_student_tt, :timetable_pdf]
    has_permission_on [:student],
                      :to => [
                          # :exam_report,
                          # :show,
                          # :academic_pdf,
                          # :guardians,
                          # :list_students_by_course,
                          # :academic_report,
                          # :previous_years_marks_overview,
                          # :previous_years_marks_overview_pdf,
                          # :reports,
                          # :student_annual_overview,
                          # :subject_wise_report,
                          # :graph_for_previous_years_marks_overview,
                          # :graph_for_student_annual_overview,
                          # :graph_for_subject_wise_report_for_one_subject,
                          # :graph_for_exam_report,
                          # :graph_for_academic_report,
                          # :show_previous_details,
                          # :fees,
                          # :fee_details,
                          :activities,
                          :update_activities
                      ]
    has_permission_on [:student],
                      :to => [
                          :profile,
                          :fees,
                          :fee_details,
                          :guardians,
                          :reports,
                          :activities,
                          :update_activities,
                          :show_previous_details,
                          :my_subjects,
                      ] do
      if_attribute :id => is { user.parent_record.user_id }
    end
    has_permission_on [:news],
                      :to => [
                          :index,
                          :load_comments,
                          :load_news,
                          :all,
                          :search_news_ajax,
                          :view,
                          :show,
                          :comment_view,
                          :add_comment,
                      ]
    has_permission_on [:news],
                      :to => [
                          :delete_comment
                      ] do
      if_attribute :author_id => is { user.id }
    end
    has_permission_on [:subject], :to => [:index, :list_subjects]
    has_permission_on [:timetable], :to => [:student_view, :update_timetable_view, :timetable_view_batches, :timetable_pdf]
    has_permission_on [:attendance], :to => [:student_report]
    has_permission_on [:student_attendance], :to => [:student, :leaves_report, :month, :student_report]
    has_permission_on [:finance], :to => [:student_fees_structure, :refund_student_view, :refund_student_view_pdf, :generate_fee_receipt_pdf, :generate_fee_receipt_pdf_new]
    has_permission_on [:cce_reports],
      :to => [
      :student_transcript,
      :student_report_pdf,
      :cce_full_exam_report,
      :student_fa_report_pdf
    ],:join_by=> :and do
      if_attribute :cce_enabled? => is {true}
      if_attribute :id => is {user.parent_record.user_id}
    end
    has_permission_on [:icse_reports],
                      :to => [
                          :student_report_pdf,
                          :student_transcript,
                          :student_report_csv
                      ], :join_by => :and do
      if_attribute :assess_truth => is { user.icse_enabled? }
      if_attribute :id => is { user.parent_record.user_id }
    end
    has_permission_on [:remarks], :to => [:show_common_remarks, :list_custom_remarks]
    has_permission_on [:remarks], :to => [
                                    :custom_remark_list,
                                    :remarks_history,
                                    :remarks_pdf,
                                    :remarks_csv
                                ] do
      if_attribute :has_remarks_privilege => is { true }
    end
    has_permission_on [:finance], :to => [
                                    :student_fee_receipt_pdf
                                ] do
      if_attribute :user_id => is { user.parent_record.user_id }
    end

    has_permission_on [:finance_extensions], :to => [
                                               :pay_all_fees_receipt_pdf
                                           ] do
      if_attribute :id => is_in { user.guardian_entry.wards.collect(&:id) }
    end
    has_permission_on [:finance_extensions], :to => [
                                               :generate_overall_fee_receipt_pdf
                                           ] do
      if_attribute :payee_id => is_in { user.guardian_entry.wards.collect(&:id) }
    end
    has_permission_on [:student_documents], :to => [
                                              :documents
                                          ], :join_by => :and do
      if_attribute :assess_truth => is { user.student_document_access? }
      if_attribute :id => is { user.parent_record.id }
    end
    has_permission_on [:student_documents], :to => [:download], :join_by => :and do
      if_attribute :assess_truth => is { user.student_document_access? }
      if_attribute :id => is { user.parent_record.id }
    end
    has_permission_on [:assessment_reports], :to => [
                                               :students_term_reports,
                                               :student_term_report_pdf,
                                               :student_exam_reports,
                                               :student_exam_report_pdf,
                                               :students_planner_reports,
                                               :student_plan_report_pdf,
                                               :batch_reports,
                                               :select_report,
                                               :refresh_report
                                           ] do
      if_attribute :id => is { user.parent_record.id }
    end
  end

  # employee -privileeges
  role :employee do
    includes :open
    includes :manage_roll_number_tutor
    # has_permission_on [:user], :to => [:profile,:user_change_password,:dashboard,:logout,:manage_quick_links,:login] do
    has_permission_on [:user], :to => [:profile, :dashboard, :logout, :manage_quick_links, :login] do
      if_attribute :id => is { user.id }
    end
    has_permission_on [:employee_payslips], :to => [:view_payslip_pdf] do
      if_attribute :id => is { user.id }
    end
    has_permission_on [:batches], :to => [:show, :batches_ajax, :batch_summary, :list_batches, :tab_menu_items, :get_tutors, :get_batch_span] do
      if_attribute :can_view_results? => is { true }
    end
    has_permission_on [:student], :to => [:profile, :my_subjects] do
      if_attribute :is_tutor_and_in_student_batch => true
    end
    has_permission_on [:student_records],
                      :to => [
                          :index,
                          :new,
                          :new_rg,
                          :create,
                          :manage_student_records,
                          :manage_student_records_for_course,
                          :manage_record_groups_courses,
                          :student_record_csv_export,
                          :list_students,
                          :list_students_rg,
                          :handle_record_groups,
                          :get_courses_list,
                          :get_course_batch_selector,
                          :get_batches_list,
                          :get_inactive_batches_list,
                          :cancel,
                          :student_records_for_batch,
                          :get_edit_form,
                          :destroy,
                          :individual_student_records
                      ] do
      if_attribute :has_required_controls? => is { true }
    end
    has_permission_on [:employee],
                      :to => [
                          :select_employee_department,
                          :select_student_course,
                          :show,
                          :update_activities
                      ]
    has_permission_on [:employee],
                      :to => [
                          :profile_general,
                          :profile_personal,
                          :profile_address,
                          :profile_contact,
                          :profile_bank_details,
                          :profile_payroll_details,
                          :profile_additional_details,
                          :view_payslip,
                          :view_attendance,
                          :profile,
                          :activities,
                          :profile_pdf,
                          :update_monthly_payslip
                      ] do
      if_attribute :id => is { user.id }
    end
    has_permission_on [:timetable],
                      :to => [
                          :employee_timetable,
                          :employee_timetable_pdf,
                          :update_employee_tt
                      ] do
      if_attribute :id => is { user.id }
    end
    has_permission_on [:news],
                      :to => [
                          :index,
                          :load_news,
                          :show_approved_comments,
                          :load_comments,
                          :reset_news,
                          :all,
                          :search_news_ajax,
                          :view,
                          :show,
                          :comment_view,
                          :add_comment,
                      ]
    has_permission_on [:news],
                      :to => [
                          :delete_comment
                      ] do
      if_attribute :author_id => is { user.id }
    end
    has_permission_on [:employee_attendance],
                      :to => [
                          :my_leaves,
                          :employee_leaves,
                          :leaves,
                          :my_leave_applications,
                          :validate_leave_application,
                          :leave_application,
                          :own_leave_application,
                          :cancel_application,
                          :individual_leave_applications,
                          :approve_remarks,
                          :approve_or_deny_leave,
                          :deny_remarks,
                          :cancel,
                          :employee_attendance_pdf,
                          :view_attendance,
                          :leave_application
                      ] do
      if_attribute :id => is { user.id }
    end


    has_permission_on [:employee_attendance],
                      :to => [
                          :employee_attendance_pdf,
                      ] do
      if_attribute :id => is { user.id }
    end

    has_permission_on [:employee_attendance],
                      :to => [
                          :pending_leave_applications
                      ], :join_by => :and do
      if_attribute :pending_applications => true
      if_attribute :manager => true
      if_attribute :id => is { user.id }
    end


    has_permission_on [:employee_attendance],
                      :to => [
                          :view_attendance,
                          :leave_application
                      ], :join_by => :and do
      if_attribute :manager => true
      if_attribute :in_reportees_list => true
    end

    has_permission_on [:employee_attendance],
                      :to => [
                          :reportees_leave_applications,
                          :reportees_leaves,
                          :employee_leaves
                      ], :join_by => :and do
      if_attribute :manager => true
      if_attribute :id => is { user.id }
    end

    has_permission_on [:employee_attendance],
                      :to => [
                          :additional_leave_detailed
                      ], :join_by => :and do
      if_attribute :manager => true
      if_attribute :in_reportees_list => true
    end


    has_permission_on [:reminder],
                      :to => [
                          #      :reminder,
                          #      :sent_reminder,
                          #      :view_sent_reminder,
                          :delete_reminder_by_sender,
                          :delete_reminder_by_recipient,
                          #      :view_reminder,
                          :mark_unread,
                          :pull_reminder_form,
                          :send_reminder,
                          :reminder_actions,
                          :sent_reminder_delete,
                          #      :create_reminder,
                          :to_employees,
                          :to_students,
                          :to_parents,
                          :update_recipient_list,
                          :update_recipient_list1,
                          :update_recipient_list2,
                          :model_box
                      ]
    has_permission_on [:assessment_scores],
                      :to => [
                          :fa_scores,
                          :get_fa_groups,
                          :scores_form
                      ], :join_by => :and do
      if_attribute :assess_truth => is { user.cce_enabled? }
      if_attribute :is_subject_teacher_for_this_subject => true
    end

    has_permission_on [:assessment_scores],
                      :to => [
                          :observation_groups,
                          :observation_scores,
                          :get_grade,
                          :search_batch_students
                      ], :join_by => :and do
      if_attribute :assess_truth => is { user.cce_enabled? }
      if_attribute :is_tutor_and_in_this_batch => is { true }
    end
    has_permission_on [:asl_scores],
                      :to => [
                          :show,
                          :save_scores
                      ], :join_by => :and do
      if_attribute :assess_truth => is { user.cce_enabled? }
      if_attribute :is_subject_teacher_and_teaches_this_subject => is { true }
    end

    has_permission_on :student_attendance, :to => [:index] do
      if_attribute :is_allowed_to_mark_attendance? => is { true }
    end
    has_permission_on [:attendances], :to => [:index, :list_subject, :show, :new, :create, :edit,:update, :destroy,:subject_wise_register,:quick_attendance,:notification_status,:send_sms_for_absentees,:list_subjects,:save_attendance ,:lock_attendance] do
      if_attribute :is_allowed_to_mark_attendance? => is {true}
    end
    has_permission_on [:attendance_reports], :to => [:index, :subject, :mode, :show, :year, :report, :filter, :student_details, :report_pdf, :filter_report_pdf,  :fetch_columns] do
      if_attribute :is_allowed_to_mark_attendance? => is { true }
    end
    has_permission_on [:attendance_reports], :to => [:day_wise_report, :day_wise_report_filter_by_course, :day_wise_report_filter_by_attendance_type,:daily_report_batch_wise] do
      if_attribute :can_view_day_wise_report? => is { true }
    end

    has_permission_on [:course_exam_groups],
                      :to => [
                          :index,
                          :batch_wise_exam_groups,
                          :common_exam_groups
                      ], :join_by => :or do
      if_attribute :is_a_subject_teacher => true
      if_attribute :is_a_batch_tutor => true
    end

    has_permission_on [:course_exam_groups],
                      :to => [
                          :list_tabs,
                          :list_exam_batches,
                      ], :join_by => :or do
      if_attribute :is_tutor_and_has_batch_in_this_course => true
      if_attribute :is_subject_teacher_and_has_batch_in_this_course => true
    end

    has_permission_on [:exam],
                      :to => [
                          :index,
                          :report_center,
                          :subject_wise_report,
                          :subject_rank,
                      #      :batch_groups,
                      #      :gpa_cwa_reports,
                      #      :list_batch_groups,
                      #      :load_batch_students,
                      #
                      ], :join_by => :or do
      if_attribute :is_a_subject_teacher => true
      if_attribute :is_a_batch_tutor => true
    end

    has_permission_on [:exam],
                      :to => [
                          :exam_wise_report,
                          :grouped_exam_report,
                          :batch_rank,
                          :attendance_rank,
                          :transcript,
                          :combined_report,
                      ] do
      if_attribute :is_a_batch_tutor => true
    end

    has_permission_on [:exam],
                      :to => [
                          :list_subjects,
                          :list_batch_subjects,
                          :previous_exam_marks
                      ], :join_by => :or do
      if_attribute :is_tutor_and_in_this_batch => true
      if_attribute :is_subject_teacher_and_in_this_batch => true
    end

   
    
    has_permission_on [:exam],
                      :to => [
                          :list_exam_types,
                          :generated_report,
                          :student_wise_generated_report,
                          :graph_for_generated_report,
                          :final_report_type,
                          :generated_report4,
                          :generated_report4_pdf,
                          :student_batch_rank,
                          :student_batch_rank_pdf,
                          :student_attendance_rank,
                          :student_attendance_rank_pdf,
                          :student_transcript,
                          :student_transcript_pdf,
                          :load_levels,
                          :student_combined_report,
                          :student_combined_report_pdf,
                          :consolidated_exam_report,
                          :generated_report_pdf,
                          :consolidated_exam_report_pdf,
                          :combined_grouped_exam_report_pdf,
                          :generated_report3,
                          :graph_for_generated_report3
                      ] do
      if_attribute :is_tutor_and_in_this_batch => true
    end

    has_permission_on [:exam],
                      :to => [
                          :generated_report2,
                          :generated_report2_pdf,
                          :student_subject_rank,
                          :student_subject_rank_pdf,
                          :edit_previous_marks,
                          :update_previous_marks
                      ], :join_by => :or do
      if_attribute :is_tutor_in_this_batch => true
      if_attribute :is_subject_teacher_for_this_subject => true
    end

    #    has_permission_on [:exam],
    #      :to => [
    #      :create_exam,
    #    ] , :join_by => :and do
    #      if_attribute :is_a_batch_tutor => true
    #    end




    has_permission_on [:exam_groups],
                      :to => [
                          :index,
                          :show,
                      ], :join_by => :or do
      if_attribute :is_tutor_and_in_this_batch => true
      if_attribute :is_subject_teacher_and_in_this_batch => true
    end
    has_permission_on [:exam_groups],
                      :to => [
                          :subject_list
                      ], :join_by => :and do
      if_attribute :assess_truth => is { user.cce_enabled? }
      if_attribute :is_subject_teacher_and_in_this_batch => true
    end

    has_permission_on [:cce_report_settings],
                      :to => [
                          :upscale_scores,
                          :save_upscale_scores,
                          :get_course_batch_selector,
                      ], :join_by => :and do
      if_attribute :assess_truth => is { user.cce_enabled? }
      if_attribute :is_tutor_and_in_this_batch => true
    end

    has_permission_on [:cce_report_settings],
                      :to => [
                          :cancel,
                          :get_batches_list,
                          :get_inactive_batches_list
                      ], :join_by => :and do
      if_attribute :assess_truth => is { user.cce_enabled? }
      if_attribute :is_tutor_and_has_batch_in_this_course => true
    end

    has_permission_on [:exams],
                      :to => [
                          :show,
                          :save_scores
                      ], :join_by => :and do
      if_attribute :is_subject_teacher_and_teaches_this_subject => is { true }
    end

    has_permission_on [:exam_reports],
                      :to => [
                          :archived_exam_wise_report,
                      ] do
      if_attribute :is_a_batch_tutor => true
    end

    has_permission_on [:exam_reports],
                      :to => [
                          :list_inactivated_batches,
                      #
                      #      :consolidated_exam_report,
                      #      :consolidated_exam_report_pdf,
                      #
                      #      :graph_for_archived_batches_exam_report
                      ] do
      if_attribute :is_tutor_and_has_batch_in_this_course => true
    end

    has_permission_on [:exam_reports],
                      :to => [
                          :final_archived_report_type,
                          :archived_batches_exam_report,
                          :archived_batches_exam_report_pdf,
                      ] do
      if_attribute :is_tutor_and_in_this_batch => true
    end

    has_permission_on [:cce_reports],
                      :to => [
                          :detailed_fa_batches,
                          :detailed_fa_list_subjects,
                          :detailed_fa_list_fa_groups,
                          :generated_detailed_fa_report,
                          :generated_detailed_fa_report_csv,
                      ], :join_by => :and do
      if_attribute :assess_truth => is { user.cce_enabled? }
      if_attribute :is_a_batch_tutor => true
    end

    has_permission_on [:cce_reports],
                      :to => [
                          :subject_wise_batches,
                      ], :join_by => :or do
      if_attribute :assess_truth => is { user.cce_enabled? }, :is_tutor_and_has_batch_in_this_course => true
      if_attribute :assess_truth => is { user.cce_enabled? }, :is_subject_teacher_and_has_batch_in_this_course => true
    end

    has_permission_on [:cce_reports],
                      :to => [
                          :list_batches,
                          :list_previous_batches
                      ], :join_by => :and do
      if_attribute :assess_truth => is { user.cce_enabled? }
      if_attribute :is_tutor_and_has_batch_in_this_course => true
    end

    has_permission_on [:cce_reports],
                      :to => [
                          :list_subjects,
                      ], :join_by => :or do
      if_attribute :assess_truth => is { user.cce_enabled? }, :is_tutor_and_in_this_batch => true
      if_attribute :assess_truth => is { user.cce_enabled? }, :is_subject_teacher_and_in_this_batch => true
    end

    has_permission_on [:cce_reports],
                      :to => [
                          :generate_student_wise_report,
                          :student_report,
                          :update_assessment_groups,

                          :generated_report,
                          :generated_report_csv,
                          :generated_report_pdf,
                          :list_exam_groups,
                          :list_observation_groups,
                          :generate_cbse_co_scholastic_report,
                          :generate_cbse_co_scholastic_report_csv,
                          :list_asl_groups,
                          :generate_asl_report,
                          :asl_report_csv,

                          :generate_previous_batch_exam_reports
                      ], :join_by => :and do
      if_attribute :assess_truth => is { user.cce_enabled? }
      if_attribute :is_tutor_and_in_this_batch => true
    end

    has_permission_on [:cce_reports],
                      :to => [
                          :cce_full_exam_report,
                          :student_transcript,
                          :student_report_pdf,
                      ], :join_by => :and do
      if_attribute :assess_truth => is { user.cce_enabled? }
      if_attribute :is_tutor_and_in_student_batch => true
    end

    has_permission_on [:cce_reports],
                      :to => [
                          :subject_wise_generated_report,
                          :subject_wise_generated_report_csv,
                          :subject_wise_generated_report_pdf
                      ], :join_by => :or do
      if_attribute :assess_truth => is { user.cce_enabled? }, :is_tutor_in_this_batch => true
      if_attribute :assess_truth => is { user.cce_enabled? }, :is_subject_teacher_for_this_subject => true
    end

    has_permission_on [:cce_reports],
                      :to => [
                          :generate_cbse_scholastic_report,
                          :generate_cbse_scholastic_report_csv
                      ], :join_by => :and do
      if_attribute :assess_truth => is { user.cce_enabled? }
      if_attribute :is_tutor_in_this_batch => true
    end

    has_permission_on [:student],
                      :to => [
                          :reports
                      ] do
      if_attribute :is_tutor_and_in_student_batch => true
    end

    has_permission_on [:cce_reports],
                      :to => [
                          :index,
                          :subject_wise_report,
                          :student_wise_report,
                          :consolidated_report,
                          :detailed_fa_report,
                          :cbse_report,
                          :upscale_report,
                          :asl_report,
                          :cbse_scholastic_report,
                          :cbse_co_scholastic_report,
                          :previous_batch_exam_reports,
                      ], :join_by => :and do
      if_attribute :assess_truth => is { user.cce_enabled? }
      if_attribute :is_batch_tutor_or_subject_teacher_in_cce_course => true
    end



    has_permission_on [:attendances], :to => [:daily_register]
    has_permission_on [:attendance_reports], :to => [:student]
    has_permission_on [:ia_scores],
                      :to => [
                          :ia_scores,
                          :update_ia_score
                      ], :join_by => :and do
      if_attribute :assess_truth => is { user.icse_enabled? }
      if_attribute :is_subject_teacher_and_teaches_this_subject => is { true }
    end

    has_permission_on [:icse_reports],
                      :to => [
                          :student_wise_report,
                          :consolidated_report,
                      ], :join_by => :and do
      if_attribute :assess_truth => is { user.icse_enabled? }, :is_a_subject_teacher => true
      if_attribute :assess_truth => is { user.icse_enabled? }, :is_a_batch_tutor => true
    end

    has_permission_on [:icse_reports],
                      :to => [
                          :index,
                          :subject_wise_report,
                      ], :join_by => :or do
      if_attribute :assess_truth => is { user.icse_enabled? }, :is_a_subject_teacher => true
      if_attribute :assess_truth => is { user.icse_enabled? }, :is_a_batch_tutor => true
    end

    has_permission_on [:icse_reports],
                      :to => [
                          :list_batches,
                      ], :join_by => :or do
      if_attribute :assess_truth => is { user.icse_enabled? }, :is_tutor_and_has_batch_in_this_course => true
      if_attribute :assess_truth => is { user.icse_enabled? }, :is_subject_teacher_and_has_batch_in_this_course => true
    end

    has_permission_on [:icse_reports],
                      :to => [
                          :list_subjects,
                      ], :join_by => :or do
      if_attribute :assess_truth => is { user.icse_enabled? }, :is_tutor_and_in_this_batch => true
      if_attribute :assess_truth => is { user.icse_enabled? }, :is_subject_teacher_and_in_this_batch => true
    end


    has_permission_on [:icse_reports],
                      :to => [
                          :list_exam_groups,
                          :subject_wise_generated_report,
                          :internal_and_external_mark_csv,
                          :internal_and_external_mark_pdf,
                      ], :join_by => :or do
      if_attribute :assess_truth => is { user.icse_enabled? }, :is_tutor_in_this_batch => true
      if_attribute :assess_truth => is { user.icse_enabled? }, :is_subject_teacher_for_this_subject => true
    end


    has_permission_on [:icse_reports],
                      :to => [
                          :student_wise_report,
                          :consolidated_report,
                          :previous_batch_exam_reports,
                      ], :join_by => :and do
      if_attribute :assess_truth => is { user.icse_enabled? }
      if_attribute :is_a_batch_tutor => true
    end



    has_permission_on [:icse_reports],
                      :to => [
                          :generate_student_wise_report,
                          :student_report_pdf,
                          :student_report_csv,
                          :student_report,
                          :consolidated_generated_report,
                          :consolidated_report_csv,

                          :detailed_internal_and_external_mark_pdf,
                          :detailed_internal_and_external_mark_csv,
                          :list_previous_batches,
                          :generate_previous_batch_exam_reports
                      ], :join_by => :and do
      if_attribute :assess_truth => is { user.icse_enabled? }
      if_attribute :is_tutor_and_in_this_batch => true
    end

    has_permission_on [:icse_reports],
                      :to => [
                          :student_transcript,
                      ], :join_by => :and do
      if_attribute :assess_truth => is { user.icse_enabled? }
      if_attribute :is_tutor_and_in_student_batch => true
    end





    has_permission_on [:remarks],
                      :to => [
                          :edit_remarks,
                          :update_remarks,
                          :add_remarks,
                          :create_remarks,
                          :destroy,
                          :edit_common_remarks,
                          :update_common_remarks,
                          :destroy_common_remarks,
                          :show_common_remarks
                      ] do
      if_attribute :has_employee_privilege => is { true }
    end
    has_permission_on [:remarks],
                      :to => [
                          :custom_remark_list,
                          :remarks_pdf,
                          :remarks_csv
                      ] do
      if_attribute :is_tutor_and_in_student_batch => true
    end
    has_permission_on [:remarks],
                      :to => [
                          :index,
                          :add_employee_custom_remarks,
                          :employee_list_custom_remarks,
                          :list_students,
                          :list_custom_remarks,
                          :list_student_with_remark_subject,
                          :employee_custom_remark_update,
                          :edit_custom_remarks,
                          :destroy_custom_remarks,
                          :update_custom_remarks,
                          :list_batches,
                          :list_specific_batches
                      ] do
      if_attribute :can_view_results? => is { true }
    end
    has_permission_on [:report], :to => [:csv_reports, :csv_report_download, :pdf_reports, :pdf_report_download]
    has_permission_on [:csv_export], :to => [:generate_csv]

    has_permission_on [:gradebooks],
      :to =>[
        :index,
        :exam_management,
        :course_assessment_groups,
        :change_academic_year
      ],:join_by => :or do
        if_attribute :is_a_batch_tutor => is {true}
        if_attribute :is_a_subject_teacher => is {true}
      end
    
    has_permission_on [:gradebook_attendance],
      :to =>[
      :attendance_entry
      ]do
        if_attribute :is_tutor_and_has_batch_in_this_course => is {true}
      end
    
    has_permission_on [:assessments],
        :to =>[
          :show
        ],:join_by => :or do
          if_attribute :is_tutor_and_has_batch_in_this_course => true
          if_attribute :is_subject_teacher_and_has_batch_in_this_course => true
        end

    has_permission_on [:assessments],
        :to =>[
          :subject_scores,
          :attribute_scores,
          :activity_scores,
          :skill_scores
        ]do
          if_attribute :is_tutor_in_this_batch => true
          if_attribute :is_subject_teacher_for_this_subject => true
      end

    has_permission_on [:assessments],
        :to =>[
          :manage_derived_assessment
        ]do
          if_attribute :is_tutor_and_has_batch_in_this_course => true
      end

    has_permission_on [:assessment_reports],
      :to =>[
      :generate_exam_reports,
      :student_exam_reports,
      :refresh_students,
      :refresh_report,
      :publish_reports,
      :regenerate_reports,
      :students_term_reports,
      :generate_term_reports,
      :generate_planner_reports,
      :students_planner_reports,
      :student_exam_report_pdf,
      :student_term_report_pdf,
      :student_plan_report_pdf,
      :generate_batch_wise_reports
    ]do
      if_attribute :is_a_batch_tutor => true
    end
      
    has_permission_on [:cce_reports],
      :to =>[
      :batch_wise_student_report_download
    ]do
      if_attribute :is_a_batch_tutor => true
    end

    has_permission_on [:assessments],
        :to =>[
          :calculate_derived_marks
        ]do
          if_attribute :is_tutor_in_this_batch => true
      end
      
    has_permission_on [:gradebook_remarks],
        :to =>[
          :manage,
          :update_report_type,
          :update_reportable,
          :update_remark_type,
          :update_remarkable,
          :update_student_list,
          :update_remark,
          :add_from_remark_bank,
          :update_remark_templates,
          :update_remark_preview
        ]do  
          if_attribute :is_tutor_and_has_batch_in_this_course => true
          if_attribute :is_subject_teacher_and_has_batch_in_this_course => true
      end

   has_permission_on [:gradebook_reports], :to => [
            :index,
            :student_reports,
            :subject_reports,
            :change_academic_year,
            :subject_wise_generated_report,
            :student_wise_generated_report,
            :reload_batches,
            :reload_subjects,
            :reload_exams,
            :reload_report_type,
            :reload_reports,
            :reload_students,
      #      :consolidated_reports,
            :consolidated_exam_report,
            :reload_consolidated_exams,
            :reload_cosolidated_exam_types,
            :reload_checkboxes,
            :show_consolidated_exam_report  
    ]do
      if_attribute :is_a_batch_tutor => true
    end
  end

  role :subject_attendance do
    has_permission_on [:csv_export], :to => [:generate_csv]
    has_permission_on [:attendances], :to => [:index, :list_subject, :show, :new, :create, :edit,:update, :destroy,:subject_wise_register,:quick_attendance,:notification_status,:send_sms_for_absentees]
    has_permission_on [:attendance_reports], :to => [:index,:subjectwise_report, :subject, :mode, :show, :year, :report, :filter, :student_details,:report_pdf,:filter_report_pdf,:consolidated_report]
  end

  role :subject_exam do
    has_permission_on [:exam],
                      :to => [
                          :index,
                          #      :create_exam,
                          :update_batch,
                          :exam_wise_report,
                          :list_exam_types,
                          :generated_report,
                          :graph_for_generated_report,
                          :generated_report_pdf,
                          :student_wise_generated_report,
                          :consolidated_exam_report,
                          :consolidated_exam_report_pdf,
                          :subject_wise_report,
                          :subject_rank,
                          :course_rank,
                          :batch_groups,
                          :student_course_rank,
                          :student_course_rank_pdf,
                          :student_school_rank,
                          :student_school_rank_pdf,
                          :attendance_rank,
                          :student_attendance_rank,
                          :student_attendance_rank_pdf,
                          :report_center,
                          :gpa_cwa_reports,
                          :list_batch_groups,
                          :ranking_level_report,
                          :student_ranking_level_report,
                          :student_ranking_level_report_pdf,
                          :transcript,
                          :student_transcript,
                          :student_transcript_pdf,
                          :combined_report,
                          :load_levels,
                          :student_combined_report,
                          :student_combined_report_pdf,
                          :load_batch_students,
                          :select_mode,
                          :select_batch_group,
                          :select_type,
                          :select_report_type,
                          :batch_rank,
                          :student_batch_rank,
                          :student_batch_rank_pdf,
                          :student_subject_rank,
                          :student_subject_rank_pdf,
                          :list_subjects,
                          :list_batch_subjects,
                          :generated_report2,
                          :generated_report2_pdf,
                          :grouped_exam_report,
                          :final_report_type,
                          :generated_report4,
                          :generated_report4_pdf,
                          :combined_grouped_exam_report_pdf
                      ]
    has_permission_on [:exam_groups],
                      :to => [
                          :index,
                          :show,
                          :set_exam_maximum_marks,
                          :set_exam_minimum_marks,
                          :subject_list
                      ]
    has_permission_on [:exams],
                      :to => [
                          :show,
                          :save_scores
                      ]
    #    has_permission_on [:additional_exam],
    #      :to =>[
    #      :create_additional_exam,
    #      :update_batch
    #    ]
    #    has_permission_on [:additional_exam_groups],
    #      :to =>[
    #      :index,
    #      :show,
    #      :set_additional_exam_minimum_marks,
    #      :set_additional_exam_maximum_marks,
    #      :set_additional_exam_weightage,
    #      :set_additional_exam_group_name
    #    ]
    #    has_permission_on [:additional_exams],
    #      :to => [
    #      :index,
    #      :show,
    #      :save_additional_scores
    #    ]
  end

  role :archived_exam_reports do
    has_permission_on [:exam_reports],
                      :to => [
                          :archived_exam_wise_report,
                          :list_inactivated_batches,
                          :final_archived_report_type,
                          :consolidated_exam_report,
                          :consolidated_exam_report_pdf,
                          :archived_batches_exam_report,
                          :archived_batches_exam_report_pdf,
                          :graph_for_archived_batches_exam_report
                      ]
  end
  role :reports_view do
    has_permission_on [:report],
                      :to => [
                          :index,
                          :course_batch_details,
                          :course_batch_details_csv,
                          :batch_details,
                          :batch_details_csv,
                          :batch_students,
                          :batch_students_csv,
                          :course_students,
                          :course_students_csv,
                          :students_all,
                          :students_all_csv,
                          :employees,
                          :employees_csv,
                          :former_students,
                          :former_students_csv,
                          :subject_details,
                          :list_batches,
                          :subject_details_csv,
                          :exam_schedule_details,
                          :batch_list,
                          :batch_list_active,
                          :exam_schedule_details_csv,
                          :fee_collection_details,
                          :fee_collection_details_csv,
                          :batch_details_all,
                          :batch_details_all_csv,
                          :course_fee_defaulters,
                          :course_fee_defaulters_csv,
                          :batch_fee_defaulters,
                          :batch_fee_defaulters_csv,
                          :students_fee_defaulters,
                          :students_fee_defaulters_csv,
                          :batch_fee_collections,
                          :batch_fee_collections_csv,
                          :student_wise_fee_defaulters,
                          :send_sms,
                          :student_wise_fee_defaulters_csv,
                          :student_wise_fee_collections,
                          :student_wise_fee_collections_csv,
                          :csv_reports,
                          :csv_report_download,
                          :search_student,
                          :search_ajax,
                          :student_fees_headwise_report,
                          :student_fees_headwise_report_pdf,
                          :student_fees_headwise_report_csv,
                          :fees_head_wise_report,
                          :batch_fees_headwise_report,
                          :fee_collection_report,
                          :batch_head_wise_fees_csv,
                          :collection_report_csv,
                          :batch_selector,
                          :fee_collection_head_wise_report,
                          :update_fees_collections,
                          :fee_collection_head_wise_report_csv,
                          :pdf_reports,
                          :pdf_report_download
                      ]

    has_permission_on [:report], :to => [:former_employees, :former_employees_csv] do
      if_attribute :search_privilege => true
    end
    has_permission_on [:report], :to => [:employee_subject_association, :employee_subject_association_csv] do
      if_attribute :subject_association_privilege => true
    end
    has_permission_on [:report], :to => [:employee_payroll_details, :employee_payroll_details_csv] do
      if_attribute :payroll_privilege => true
    end
    has_permission_on [:report], :to => [:siblings_report, :siblings_course_select, :siblings_report_csv] do
      if_attribute :sibling_enabled => true
    end
  end
  role :timetable_track do
    has_permission_on [:timetable_tracker],
      :to=>[
      :index,
      :class_timetable_swap,
      :batch_timetable,
      :cancel_timetable_period,
      :list_employees,
      :validate_swap_employees,
      :timetable_swap,
      :timetable_swap_from,
      :timetable_swap_delete,
      :swaped_timetable_report,
      :batch_wise,
      :list_employee_wise,
      :employee_wise,
      :employee_wise_timetable,
      :employee_report_details,
      :swaped_timetable_report_csv,
    ]
  end
  role :manage_student_record do
    has_permission_on [:student_records], :to => [
                                            :index,
                                            :new,
                                            :new_rg,
                                            :create,
                                            :manage_student_records,
                                            :manage_student_records_for_course,
                                            :manage_record_groups_courses,
                                            :student_record_csv_export,
                                            :list_students,
                                            :list_students_rg,
                                            :handle_record_groups,
                                            :get_courses_list,
                                            :get_course_batch_selector,
                                            :get_batches_list,
                                            :get_inactive_batches_list,
                                            :cancel,
                                            :student_records_for_batch,
                                            :get_edit_form,
                                            :destroy,
                                            :individual_student_records

                                        ]
    has_permission_on [:record_groups], :to => [
                                          :index,
                                          :new,
                                          :create,
                                          :edit,
                                          :update,
                                          :destroy,
                                          :delete_warning,
                                          :manage_record_groups,
                                          :add_record_groups_to_course,
                                          :assign_record_groups_to_course,
                                          :update_priority,
                                          :manage_record_groups_for_course,
                                          :record_group_settings,
                                          :save_record_group_settings_for_course,
                                          :edit_priority,
                                          :update_priority,
                                          :cancel,
                                          :student_record_preview
                                      ]
    has_permission_on [:records], :to => [
                                    :index,
                                    :new,
                                    :create,
                                    :edit,
                                    :update,
                                    :update_priority,
                                    :students_list,
                                    :show,
                                    :destroy,
                                    :preview,
                                    :cancel
                                ]
  end

  role :manage_hr_reports do
    has_permission_on [:hr_reports], :to => [
                                       :fetch_reports,
                                       :fetch_dependent_values,
                                       :fetch_filters,
                                       :report_csv,
                                       :save_template,
                                       :fetch_template_filters,
                                       :fetch_template_reports,
                                       :template_csv
                                   ]
    has_permission_on [:hr_reports], :to => [:index, :report, :template, :destroy] do
      if_attribute :approve_reject_privilege => true
    end
  end
  role :generate_tc do
    has_permission_on [:tc_templates], :to => [
                                         :index
                                     ]
    has_permission_on [:tc_template_generate_certificates], :to => [
                                                              :index,
                                                              :list_batches,
                                                              :list_students,
                                                              :generated_certificates,
                                                              :search_logic_for_archived_students,
                                                              :search_generated_records,
                                                              :edit,
                                                              :regenerate_certificate,
                                                              :preview,
                                                              :create,
                                                              :show,
                                                              :transfer_certificate_download,
                                                              :transfer_certificate_download_pdf,
                                                              :destroy,
                                                              :date_in_words
                                                          ]
  end
  role :view_tc do
    has_permission_on [:tc_templates], :to => [
                                         :index
                                     ]
    has_permission_on [:tc_template_generate_certificates], :to => [
                                                              :generated_certificates,
                                                              :search_generated_records,
                                                              :show,
                                                              :transfer_certificate_download,
                                                              :transfer_certificate_download_pdf
                                                          ]
  end
  role :manage_transfer_certificate do
    includes :generate_tc
    includes :view_tc
    has_permission_on [:tc_template_headers], :to=> [
      :edit
    ]
    has_permission_on [:tc_template_footers], :to=> [
      :edit
    ]
    has_permission_on [:tc_template_student_details], :to=> [
      :index,
      :edit,
      :update_field,
      :delete_field,
      :new_field,
      :create_new_field,
      :priority_change,
      :cancel,
      :font_size_select
    ]
    has_permission_on [:tc_templates], :to=> [
      :settings,
      :current_tc_preview
    ]
  end
  role :manage_student_attachment do
    has_permission_on [:student_documents], :to => [
                                              :new,
                                              :create,
                                              :edit,
                                              :update,
                                              :destroy,
                                              :documents,
                                              :download
                                          ]
  end
  role :manage_student_attachment_categories do
    has_permission_on [:configuration], :to => [
                                          :student_document_manager
                                      ]
    has_permission_on [:student_document_categories], :to => [
                                                        :new,
                                                        :create,
                                                        :edit,
                                                        :update,
                                                        :destroy,
                                                        :show,
                                                        :index,
                                                        :confirm_destroy
                                                    ]
  end

  role :view_student_attachment do
    has_permission_on [:student_documents], :to => [
                                              :documents,
                                              :download
                                          ]
  end

  role :manage_feature_access_settings do
    has_permission_on [:feature_access_settings], :to => [
                                                    :index,
                                                    :create
                                                ]
  end

  role :manage_message do
    has_permission_on [:messages], :to => [
                                     :message_settings
                                 ]
  end
  
  role :message_template_management do
    has_permission_on [:message_templates], :to => [
      :new_message_template,
      :save_message_template,
      :edit_message_template,
      :update_message_template,
      :message_templates,
      :delete_message_template,
      :list_keys_for_template
    ]
  end

  role :certificate_management do
    includes :manage_template
    has_permission_on [:certificate_templates], :to => [
      :index,
      :certificate_templates,
      :new_certificate_template,
      :edit_certificate_template,
      :update_certificate_template,
      :delete_certificate_template,
      :save_certificate_template,
      :generate_certificate,
      :certificate_keys,
      :certificate_template_for_generation,
      :download_image,
      :save_generated_certificate,
      :generate_certificate_pdf,
      :generated_certificates,
      :list_generated_certificates,
      :generated_certificates_list,
      :bulk_export,
      :bulk_export_group_selector,
      :batch_students,
      :department_employees,
      :generate_bulk_export_pdf_student,
      :generate_bulk_export_pdf_employee,
      :load_certificate_key_form,
      :generate_bulk_export_sample_preview,
      :save_bulk_generated_certificate,
      :generate_bulk_export_pdf,
      :bulk_generated_certificates_list,
      :batch_selector,
      :delete_generated_certificate,
      :delete_bulk_generated_certificate
    ]
  end

  role :id_card_management do
    includes :manage_template
    has_permission_on [:id_card_templates], :to => [
      :index,
      :id_card_templates,
      :settings,
      :new_id_card_template,
      :save_id_card_template,
      :edit_id_card_template,
      :update_id_card_template,
      :delete_id_card_template,
      :id_card_keys,
      :download_image,
      :generate_id_card,
      :id_card_template_for_generation,
      :save_generated_id_card,
      :generated_id_cards,
      :list_generated_id_cards,
      :generated_id_cards_list,
      :generate_id_card_pdf,
      :load_id_card_key_form,
      :bulk_export,
      :bulk_export_group_selector,
      :batch_students,
      :department_employees,
      :generate_bulk_export_pdf_student,
      :generate_bulk_export_pdf_employee,
      :generate_bulk_export_pdf_guardian,
      :generate_bulk_export_sample_preview,
      :save_bulk_generated_id_card,
      :generate_bulk_export_pdf,
      :bulk_generated_id_cards_list,
      :batch_selector,
      :delete_generated_id_card,
      :delete_bulk_generated_id_card
    ]
  end

  role :manage_template do
    has_permission_on [:templates], :to => [
      :load_template_key_form,
      :batch_list,
      :batch_list_for_guardian,
      :student_list,
      :student_list_for_guardian,
      :guardian_list,
      :barcode_linked_to_list,
      :set_student_keys,
      :set_employee_keys,
      :set_guardian_keys
    ]
    
    has_permission_on [:generated_pdfs], :to => [
      :download_pdf
    ]
  end

  role :manage_gradebook do
    has_permission_on [:gradebook_reports], :to => [
      :index,
      :student_reports,
      :subject_reports,
      :change_academic_year,
      :subject_wise_generated_report,
      :student_wise_generated_report,
      :reload_batches,
      :reload_subjects,
      :reload_exams,
      :reload_report_type,
      :reload_reports,
      :reload_students,
      :consolidated_reports,
      :consolidated_exam_report,
      :reload_consolidated_exams,
      :reload_cosolidated_exam_types,
      :reload_checkboxes,
      :show_consolidated_exam_report
    ]
    has_permission_on [:gradebook_attendance], :to => [
      :attendance_entry,
      :load_types,
      :load_subtypes,
      :load_button,
      :list_students,
      :submit_attendance,
      :attendance_period
    ]
    has_permission_on [:gradebooks], :to => [
                                       :index,
                                       :settings,
                                       :exam_management,
                                       :course_assessment_groups,
                                       :list_course_exam_groups,
                                       :list_course_plan_details,
                                       :change_academic_year
                                   ]
    has_permission_on [:assessment_activities], :to => [
                                                  :index,
                                                  :show,
                                                  :load_activities,
                                                  :new,
                                                  :create,
                                                  :edit,
                                                  :update,
                                                  :destroy,
                                                  :add_activities,
                                                  :update_activities
                                              ]
    has_permission_on [:assessment_attributes], :to => [
                                                  :index,
                                                  :show,
                                                  :load_attributes,
                                                  :new,
                                                  :create,
                                                  :edit,
                                                  :update,
                                                  :destroy,
                                                  :add_attributes,
                                                  :update_attributes
                                              ]
    has_permission_on [:remark_banks], :to => [
                                                  :index,
                                                  :show,
                                                  :new,
                                                  :create,
                                                  :edit,
                                                  :update,
                                                  :destroy
                                              ]
    has_permission_on [:gradebook_remarks], :to => [
      :manage,
      :update_report_type,
      :update_reportable,
      :update_remark_type,
      :update_remarkable,
      :update_student_list,
      :update_remark,
      :add_from_remark_bank,
      :update_remark_templates,
      :update_remark_preview
    ]
    has_permission_on [:assessment_plans], :to => [
                                             :index,
                                             :new,
                                             :create,
                                             :build_terms,
                                             :show,
                                             :manage_courses,
                                             :add_courses,
                                             :unlink_course,
                                             :change_academic_year,
                                             :delete_assessment_group,
                                             :destroy,
                                             :delete_planner_assessment,
                                             :set_assessment_term_name,
                                             :set_assessment_plan_name,
                                             :import_planner,
                                             :reimport_planner,
                                             :refresh_from_academic_year,
                                             :update_planner_form,
                                             :import_logs,
                                             :edit_assessment_term,
                                             :update_assessment_term,
                                             :delete_term
                                         ]
    has_permission_on [:assessment_imports], :to => [
      :imports,
      :new,
      :create,
      :import_form,
      :show_log
    ]
    has_permission_on [:grading_profiles], :to => [
      :index,
      :show,
      :new,
      :create,
      :edit,
      :update,
      :destroy,
      :add_grades,
      :update_grades,
      :set_default,
      :update_default,
      :fetch_details
    ]
    has_permission_on [:assessment_groups], :to => [
                                              :new,
                                              :create,
                                              :edit,
                                              :update,
                                              :fetch_profiles,
                                              :new_course_exam,
                                              :course_exam_form,
                                              :create_course_exam,
                                              :edit_course_exam,
                                              :update_course_exam,
                                              :change_group_type,
                                              :final_term_assessment,
                                              :edit_final_term,
                                              :update_final_term,
                                              :create_final_term,
                                              :planner_assessment,
                                              :reorder_assessments,
                                              :fetch_assessment_groups,
                                              :fetch_final_term_assessment_groups,
                                              :fetch_final_term_assessment_groups_new
                                          ]
    has_permission_on [:academic_years], :to => [
                                           :index,
                                           :new,
                                           :create,
                                           :edit,
                                           :update,
                                           :set_active,
                                           :update_active,
                                           :fetch_details,
                                           :delete_year
                                       ]
    has_permission_on [:assessments], :to => [
      :show,
      :notification_group_selector,
      :send_notification,
      :schedule_dates,
      :save_schedule,
      :schedule_dates,
      :link_attributes,
      :update_profile_info,
      :activate_exam,
      :show,
      :schedule_dates,
      :new,
      :edit_dates,
      :create,
      :edit,
      :update,
      :destroy,
      :create,
      :attribute_scores,
      :activity_scores,
      :subject_scores,
      :exam_timings,
      :fetch_groups,
      :fetch_batches,
      :fetch_timetables,
      :exam_timings_pdf,
      :reset_assessments,
      :manage_derived_assessment,
      :show_derived_mark,
      :calculate_derived_marks,
      :activate_subject,
      :skill_scores,
      :unlock_assessments,
      :unlock_subjects
    ]
    has_permission_on [:assessment_reports], :to => [
      :settings,
      :report_header_info,
      :report_signature_info,
      :preview,
      :students_term_reports,
      :refresh_students,
      :refresh_report,
      :student_term_report_pdf,
      :generate_exam_reports,
      :generate_term_reports,
      :regenerate_reports,
      :student_exam_reports,
      :student_exam_report_pdf,
      :publish_reports,
      :generate_planner_reports,
      :students_planner_reports,
      :student_plan_report_pdf,
      :generate_batch_wise_reports,
      :batch_reports,
      :select_report,
      :advanced_report_settings,
      :attendance_settings,
      :fetch_profiles,
      :records_and_remarks_settings,
      :load_record_items,
      :manage_links,
      :save_record_group_links,
      :destroy,
      :reorder_record_groups,
      :fetch_templates,
      :template_preview,
      :preview_img,
      :general_settings,
      :send_result_publish_notification
    ]
  end

  role :gradebook_mark_entry do
    has_permission_on [:gradebooks], :to => [
      :index,
      :exam_management,
      :course_assessment_groups,
      :list_course_exam_groups,
      :list_course_plan_details,
      :change_academic_year,
      :attendance_entry
    ]
    has_permission_on [:assessments], :to => [
      :show,
      :update_profile_info,
      :show,
      :attribute_scores,
      :activity_scores,
      :subject_scores,
      :exam_timings,
      :fetch_groups,
      :fetch_batches,
      :fetch_timetables,
      :exam_timings_pdf,
      :generate_reports,
      :manage_derived_assessment,
      :show_derived_mark,
      :calculate_derived_marks,
      :skill_scores
    ]
    has_permission_on [:assessment_reports], :to => [
                                               :settings,
                                               :report_header_info,
                                               :report_signature_info,
                                               :preview,
                                               :students_term_reports,
                                               :refresh_students,
                                               :refresh_report,
                                               :student_term_report_pdf,
                                               :generate_exam_reports,
                                               :generate_term_reports,
                                               :regenerate_reports,
                                               :student_exam_reports,
                                               :student_exam_report_pdf,
                                               :publish_reports,
                                               :generate_planner_reports,
                                               :students_planner_reports,
                                               :student_plan_report_pdf,
                                               :generate_batch_wise_reports,
                                               :fetch_profiles
                                           ]
    has_permission_on [:assessment_imports], :to => [
      :imports,
      :new,
      :create,
      :import_form,
      :show_log
    ]
    has_permission_on [:gradebook_remarks], :to => [
      :manage,
      :update_report_type,
      :update_reportable,
      :update_remark_type,
      :update_remarkable,
      :update_student_list,
      :update_remark,
      :add_from_remark_bank,
      :update_remark_templates,
      :update_remark_preview
    ]
  end
  
  role :manage_subjects do
    has_permission_on [:subjects_center], :to => [
      :index,
      :course_subjects,
      :list_subjects,
      :new_component,
      :create_component,
      :edit_component,
      :update_component,
      :link_batches,
      :subject_link_form,
      :subject_link_sub_form,
      :link_batches_submission,
      :reorder_components,
      :connect_subjects,
      :list_connectable_subjects,
      :unlink_subject,
      :link_subjects,
      :delete_component,
      :list_connectable_batch_subjects,
      :import_subjects,
      :list_import_subjects,
      :list_import_courses,
      :import_logs
    ]
    has_permission_on [:subject_skill_sets], :to => [
      :index,
      :show,
      :new,
      :create,
      :edit,
      :update,
      :destroy,
      :add_skills,
      :update_skills,
      :add_sub_skills,
      :update_sub_skills
    ]
  end
  
  role :manage_groups do
    has_permission_on [:user_groups], :to => [
      :index,
      :create_user_group,
      :to_students,
      :to_employees,
      :to_parents,
      :update_member_list,
      :update_member_list1,
      :update_member_list2,
      :show_user_group,
      :edit_user_group,
      :destroy_user_group,
      :remove_member
    ]
  end

end
