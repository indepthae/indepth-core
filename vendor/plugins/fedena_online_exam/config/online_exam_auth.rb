authorization do

  role :view_results  do
    #online exam
    has_permission_on [:online_exam],
      :to => [
      :index,
      :view_result,
      :update_exam_list,
      :exam_result,
      :check_updating_status,
      :exam_result_pdf
    ]
  end

  role :online_exam_control do
    has_permission_on [:online_exam],
      :to => [
      :index,
      :new_online_exam,
      :modify_batch_selection,
      :list_subjects,
      :update_students_list,
      :search_evaluator,
      :new_question,
      :toggle_options_div,
      :rearrange_questions,
      :randomize_question_order,
      :update_question_positions,
      :import_questions,
      :revert_import,
      :show_course_list,
      :list_subject_codes,
      :list_questions,
      :view_question_details,
      :load_importing_form,
      :save_imported_question,
      :load_more_questions,
      :update_question_list,
      :reload_stats,
      :create_question,
      :view_online_exam,
      :show_active_exam,
      :edit_exam_group,
      :update_exam_group,
      :exam_details,
      :edit_question,
      :delete_question,
      :edit_exam_option,
      :delete_exam_option,
      :add_extra_question,
      :publish_exam,
      :publish,
      :view_result,
      :update_exam_list,
      :exam_result,
      :exam_result_pdf,
      :reset_exam,
      :update_student_exam,
      :update_student_list,
      :update_reset_exam,
      :check_updating_status,
      :delete_exam_group
    ]
  end

  role :examination_control do
    includes :online_exam_control
  end

  role :admin do
    includes :online_exam_control
  end

  role :student do
    has_permission_on [:online_student_exam],
      :to => [
      :index,
      :start_exam,
      :save_exam,
      :save_scores,
      :save_final_score,
      :started_exam,
      :check_updating_status,
      :view_results
    ] do
      if_attribute :student => is {true}
    end
    has_permission_on [:online_student_exam],
      :to => [:view_answersheet] do
      if_attribute :student_eligible_to_access? => is {true}
    end
  end

  role :employee do
    has_permission_on [:online_student_exam],
      :to => [:check_updating_status]
    has_permission_on [:online_exam],
      :to => [:check_updating_status]
    has_permission_on [:online_exam],
      :to => [
      :evaluator_home
    ] do
      if_attribute :has_exams_to_evaluate? => is {true}
    end
    has_permission_on [:online_exam],
      :to => [:evaluation_student_select,:publish_result,:show_student_list,:evaluate_answers] do
      if_attribute :has_valid_evaluator? => is {true}
    end

  end

end