Gretel::Crumbs.layout do

  crumb :poll_questions_index do
    link I18n.t('poll_questions.view_all_polls'), {:controller=>"poll_questions",:action=>"index"}
  end

  crumb :poll_questions_new do
    link I18n.t('poll_questions.create_new_poll'), {:controller=>"poll_questions",:action=>"new"}
    parent :poll_questions_index
  end

  crumb :poll_questions_create do
    link I18n.t('poll_questions.create_new_poll'), {:controller=>"poll_questions",:action=>"create"}
    parent :poll_questions_index
  end

   crumb :poll_questions_edit do |poll|
    link I18n.t('poll_questions.edit_poll'), {:controller=>"poll_questions",:action=>"edit",:id=>poll.id}
    parent :poll_questions_index
  end

  crumb :poll_questions_update do |poll|
    link I18n.t('poll_questions.edit_poll'), {:controller=>"poll_questions",:action=>"update",:id=>poll.id}
    parent :poll_questions_index
  end

  crumb :poll_questions_show do |poll|
    link poll.title, {:controller=>"poll_questions",:action=>"show",:id=>poll.id}
    parent :poll_questions_index
  end

  crumb :poll_questions_voting do |poll|
    link I18n.t('poll_questions.vote'), {:controller=>"poll_questions",:action=>"voting",:id=>poll.id}
    parent :poll_questions_index
  end
end