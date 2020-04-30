Gretel::Crumbs.layout do

  crumb :tasks_index do
    link I18n.t('tasks.all_tasks'), {:controller=>"tasks",:action=>"index"}
  end

  crumb :tasks_show do |task|
    link task.title, {:controller=>"tasks",:action=>"show",:id=>task.id}
    parent :tasks_index
  end

  crumb :tasks_new do
    link I18n.t('tasks.new_task'), {:controller=>"tasks",:action=>"new"}
    parent :tasks_index
  end

  crumb :tasks_create do
    link I18n.t('tasks.new_task'), {:controller=>"tasks",:action=>"create"}
    parent :tasks_index
  end

  crumb :tasks_edit do |task|
    link I18n.t('tasks.edit_task'), {:controller=>"tasks",:action=>"edit",:id=>task.id}
    parent :tasks_show,task
  end

  crumb :tasks_update do |task|
    link I18n.t('tasks.edit_task'), {:controller=>"tasks",:action=>"update",:id=>task.id}
    parent :tasks_show,task
  end

  crumb :tasks_assigned_to do |task|
    link I18n.t('tasks.listing_assignees'), {:controller=>"tasks",:action=>"assigned_to",:id=>task.id}
    parent :tasks_show,task
  end
end