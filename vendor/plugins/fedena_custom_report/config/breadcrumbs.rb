Gretel::Crumbs.layout do

  crumb :custom_reports_index do
    link I18n.t('custom_reports'), {:controller=>"custom_reports",:action=>"index"}
  end

  crumb :custom_reports_generate do
    link I18n.t('generate'), {:controller=>"custom_reports",:action=>"generate"}
    parent :custom_reports_index
  end

   crumb :custom_reports_show do |report|
    link report.name, {:controller=>"custom_reports",:action=>"show",:id=>report.id}
    parent :custom_reports_index
  end
end