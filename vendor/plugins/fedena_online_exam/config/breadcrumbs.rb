Gretel::Crumbs.layout do
  crumb :online_exam_index do
    link I18n.t('online_exam_text'), {:controller=>"online_exam", :action=>"index"}
    parent :exam_index
  end
  crumb :online_exam_evaluator_home do
    link I18n.t('evaluate_online_exam'), {:controller=>"online_exam", :action=>"evaluator_home"}
    parent :online_exam_index
  end
  crumb :online_exam_evaluation_student_select do |online_exam_group|
    link online_exam_group.name, {:controller=>"online_exam", :action=>"evaluation_student_select", :id=>online_exam_group.id}
    parent :online_exam_evaluator_home
  end
  crumb :online_exam_evaluate_answers do |exam_array|
    link exam_array.last.full_name, {:controller=>"online_exam", :action=>"evaluate_answers", :id=>exam_array.first.id, :student_id=>exam_array.last.id}
    parent :online_exam_evaluation_student_select, exam_array.first
  end
  crumb :online_exam_new_online_exam do
    link I18n.t('online_exam.new_online_exam_text'), {:controller=>"online_exam", :action=>"new_online_exam"}
    parent :online_exam_index
  end
  crumb :online_exam_new_question do |online_exam_group|
    link I18n.t('online_exam.create_questions'), {:controller=>"online_exam", :action=>"new_question", :id => online_exam_group.id }
    parent :online_exam_exam_details,online_exam_group
  end
  crumb :online_exam_create_question do |online_exam_group|
    link I18n.t('online_exam.create_questions'), {:controller=>"online_exam", :action=>"new_question", :id => online_exam_group.id }
    parent :online_exam_exam_details,online_exam_group
  end
  crumb :online_exam_view_online_exam do
    link I18n.t('online_exam.view_online_exams'), {:controller=>"online_exam", :action=>"view_online_exam"}
    parent :online_exam_index
  end
  crumb :online_exam_exam_details do |exam_group|
    link exam_group.name_was, {:controller=>"online_exam", :action=>"exam_details", :id => exam_group.id }
    parent :online_exam_view_online_exam
  end
  crumb :online_exam_import_questions do |exam_group|
    link I18n.t('import_questions'), {:controller=>"online_exam", :action=>"import_questions", :id => exam_group.id }
    parent :online_exam_exam_details,exam_group
  end
  crumb :online_exam_edit_exam_group do |exam_group|
    link I18n.t('edit_text'), {:controller=>"online_exam", :action=>"edit_exam_group", :id => exam_group.id }
    parent :online_exam_exam_details, exam_group
  end
  crumb :online_exam_rearrange_questions do |exam_group|
    link I18n.t('rearrange_questions'), {:controller=>"online_exam", :action=>"rearrange_questions", :id => exam_group.id }
    parent :online_exam_exam_details, exam_group
  end
  crumb :online_exam_add_extra_question do |exam_group|
    link I18n.t('online_exam.add_questions'), {:controller=>"online_exam", :action=>"add_extra_question", :id => exam_group.id }
    parent :online_exam_exam_details, exam_group
  end
  crumb :online_exam_edit_question do |exam_group|
    link I18n.t('online_exam.edit_question_text'), {:controller=>"online_exam", :action=>"edit_question", :id => exam_group.id }
    parent :online_exam_exam_details, exam_group
  end
  crumb :online_exam_edit_exam_option do |exam_group|
    link I18n.t('online_exam.edit_option'), {:controller=>"online_exam", :action=>"edit_exam_option", :id => exam_group.id }
    parent :online_exam_exam_details, exam_group
  end
  crumb :online_student_exam_index do
    link I18n.t('online_exam_text'), {:controller=>"online_student_exam", :action=>"index"}
  end
  crumb :online_student_exam_view_results do
    link I18n.t('view_results'), {:controller=>"online_student_exam", :action=>"view_results"}
    parent :online_student_exam_index
  end
  crumb :online_student_exam_view_answersheet do |exam_attendance|
    link I18n.t('view_answersheet'), {:controller=>"online_student_exam", :action=>"view_answersheet", :id=>exam_attendance.id}
    parent :online_student_exam_view_results
  end
  crumb :online_exam_view_result do
    link I18n.t('online_exam.view_results'), {:controller=>"online_exam", :action=>"view_result" }
    parent :online_exam_index
  end
  crumb :online_exam_exam_result do |exam_group_array|
    link "#{exam_group_array.first.name} - #{exam_group_array.last.full_name}", {:controller=>"online_exam", :action=>"exam_result", :id => exam_group_array.first.id, :batch_id => exam_group_array.last.id }
    parent :online_exam_view_result
  end
  crumb :online_exam_reset_exam do
    link I18n.t('online_exam.reset_exam'), {:controller=>"online_exam", :action=>"reset_exam" }
    parent :online_exam_index
  end
end
