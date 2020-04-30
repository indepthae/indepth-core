Gretel::Crumbs.layout do

  crumb :data_exports_index do
    link I18n.t('data_exports.all_exports'), {:controller=>"data_exports",:action=>"index"}
  end

   crumb :data_exports_new do
    link I18n.t('data_exports.new_export'), {:controller=>"data_exports",:action=>"new"}
    parent :data_exports_index
  end

   crumb :data_exports_create do
    link I18n.t('data_exports.new_export'), {:controller=>"data_exports",:action=>"create"}
    parent :data_exports_index
  end

  crumb :data_exports_schedule_jobs do
    link I18n.t('data_exports.schedule_jobs'), {:controller=>"scheduled_jobs",:action=>"index"}
    parent :data_exports_index
  end

  
end