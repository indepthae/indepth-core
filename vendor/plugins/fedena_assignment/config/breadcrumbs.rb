Gretel::Crumbs.layout do
  crumb :assignments_index do
    link I18n.t('assignments_text'), {:controller=>"assignments", :action=>"index"}
  end
  crumb :assignments_new do
    link I18n.t('new_text'), {:controller=>"assignments", :action=>"new"}
    parent :assignments_index
  end
  crumb :assignments_create do
    link I18n.t('new_text'), {:controller=>"assignments", :action=>"new"}
    parent :assignments_index
  end
  crumb :assignments_show do |assignment|
    link shorten_string(assignment.title_was,20), {:controller=>"assignments", :action=>"show", :id => assignment.id }
    parent :assignments_index
  end
  crumb :assignments_edit do |assignment|
    link I18n.t('edit_text'), {:controller=>"assignments", :action=>"edit", :id => assignment.id }
    parent :assignments_show, assignment
  end
  crumb :assignments_update do |assignment|
    link I18n.t('edit_text'), {:controller=>"assignments", :action=>"edit", :id => assignment.id }
    parent :assignments_show, assignment
  end
  crumb :assignment_answers_new do |assignment|
    link I18n.t('assignment_answers.answer'), {:controller=>"assignment_answers", :action=>"new", :assignment_id => assignment.id }
    parent :assignments_show, assignment
  end
  crumb :assignment_answers_create do |assignment|
    link I18n.t('assignment_answers.answer'), {:controller=>"assignment_answers", :action=>"new", :assignment_id => assignment.id }
    parent :assignments_show, assignment
  end
  crumb :assignment_answers_show do |assignment_answer|
    link shorten_string(assignment_answer.title_was,20), {:controller=>"assignment_answers", :action=>"show", :id => assignment_answer.id, :assignment_id => assignment_answer.assignment_id }
    parent :assignments_show, assignment_answer.assignment
  end
  crumb :assignment_answers_edit do |assignment_answer|
    link I18n.t('assignment_answers.edit_answer'), {:controller=>"assignment_answers", :action=>"edit", :id =>:assignment_answer.id, :assignment_id => assignment_answer.assignment_id }
    parent :assignments_show, assignment_answer.assignment
  end
  crumb :assignment_answers_update do |assignment_answer|
    link I18n.t('assignment_answers.edit_answer'), {:controller=>"assignment_answers", :action=>"edit", :id =>:assignment_answer.id, :assignment_id => assignment_answer.assignment_id }
    parent :assignments_show, assignment_answer.assignment
  end
end
