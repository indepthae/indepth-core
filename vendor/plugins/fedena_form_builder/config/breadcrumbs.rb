Gretel::Crumbs.layout do
  crumb :form_builder_index do
    link I18n.t('form_builder_text'), {:controller=>"form_builder",:action=>"index"}
  end

  crumb :form_templates_index do
    link I18n.t('form_templates.text'), {:controller=>"form_templates",:action=>"index"}
    parent :form_builder_index
  end

  crumb :form_templates_new do
    link I18n.t('form_templates.create'), {:controller=>"forms",:action=>"index"}
    parent :form_builder_index
  end

  crumb :form_templates_edit do
    link I18n.t('form_templates.edit'), {:controller=>"forms",:action=>"edit"}
    parent :form_templates_index
  end

  crumb :form_templates_preview do |template|
    link "#{template.name}", {:controller=>"form_templates",:action=>"show", :id => template}
    parent :form_templates_index, template
  end

  crumb :forms_index do
    link I18n.t('forms.text'), {:controller=>"forms",:action=>"index"}
    parent :form_builder_index
  end

  crumb :forms_feedback_forms do
    link I18n.t('forms.feedback_text'), {:controller=>"forms",:action=>"feedback_forms"}
    parent :form_builder_index
  end

  crumb :forms_preview do
    link I18n.t('forms.preview'), {:controller=>"forms",:action=>"preview"}
    parent :form_submissions_show
  end

  crumb :forms_manage do
    link I18n.t('forms.manage_text'), {:controller=>"forms",:action=>"manage"}
    parent :form_builder_index
  end

  crumb :forms_publish do
    link I18n.t('forms.publish_text'), {:controller=>"forms",:action=>"publish"}
    parent :form_templates_index
  end

  crumb :forms_edit do
    link I18n.t('forms.edit'), {:controller=>"forms",:action=>"edit"}
    parent :forms_manage
  end

  crumb :forms_update do
    link I18n.t('forms.edit'), {:controller=>"forms",:action=>"update"}
    parent :forms_index
  end

  crumb :forms_show do |form|
    link form.name, {:controller=>"forms",:action=>"show", :id => form.id}
    parent :forms_index
  end

  crumb :form_submissions_show do |form|
    link I18n.t('form_submissions.show'), {:controller=>"form_submissions",:action=>"show"}
    parent :forms_manage
  end

  crumb :form_submissions_responses do
    link I18n.t('form_submissions.show'), {:controller=>"forms",:action=>"index"}
    parent :forms_index
  end

  crumb :form_submissions_analysis do |form|
    link I18n.t('form_submissions.analysis'), {:controller=>"form_submissions",:action=>"analysis", :id => form.id}
    parent :form_submissions_show, form
  end

  crumb :form_submissions_consolidated_report do |form|
    link I18n.t('form_submissions.consolidated_report'), {:controller=>"form_submissions",:action=>"consolidated_report", :id => form.id}
    parent :form_submissions_show, form
  end
end