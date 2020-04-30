Gretel::Crumbs.layout do
  crumb :applicants_admins_show do
    link I18n.t('applicant_regi_label'), {:controller=>"applicants_admins", :action=>"show"}
  end
  crumb :applicants_admins_applicants do |registration_course|
    link registration_course.course.full_name, {:controller=>"applicants_admins", :action=>"applicants", :id => registration_course.id}
    parent :applicants_admins_show
  end
  crumb :applicants_admins_archived_applicants do |registration_course|
    link I18n.t('archived_applications'), {:controller=>"applicants_admins", :action=>"applicants", :id => registration_course.id}
    parent :applicants_admins_applicants, registration_course
  end
  crumb :applicants_admins_registration_settings do
    link I18n.t('settings'), {:controller=>"applicants_admins", :action=>"registration_settings"}
    parent :applicants_admins_show
  end
  crumb :applicants_admins_preview_form do
    link I18n.t('preview_application_form'), {:controller=>"applicants_admins", :action=>"preview_form"}
    parent :applicants_admins_show
  end
  crumb :applicants_admins_customize_form do
    link I18n.t('customize_form'), {:controller=>"applicants_admins", :action=>"customize_form"}
    parent :applicants_admins_registration_settings
  end
  crumb :applicants_admins_view_applicants do |applicant|
    link applicant.first_name_was, {:controller=>"applicants_admins", :action=>"view_applicant", :id => applicant.id}
    parent :applicants_admins_applicants, applicant.registration_course
  end
  crumb :applicants_admins_edit_applicant do |applicant|
    link I18n.t('edit_application'), {:controller=>"applicants_admins", :action=>"edit_applicant", :id => applicant.id}
    parent :applicants_admins_view_applicants, applicant
  end
  crumb :applicants_edit do |applicant|
    link I18n.t('edit_text'), {:controller=>"applicants", :action=>"edit", :id => applicant.id}
    parent :applicants_admins_view_applicants, applicant
  end
  crumb :applicants_admins_search_by_registration do
    link I18n.t('applicants.search'), {:controller=>"applicants", :action=>"search_by_registration"}
    parent :applicants_admins_show
  end
  crumb :registration_courses_registration_settings do |registration_course|
    link "#{I18n.t('settings')} - #{registration_course.course.full_name}", {:controller=>"registration_courses", :action=>"registration_settings",:id=>registration_course.id}
    parent :applicants_admins_show
  end
  crumb :registration_courses_customize_form do |registration_course|
    link "#{I18n.t('customize_form')} - #{registration_course.course.full_name}", {:controller=>"registration_courses", :action=>"customize_form",:id=>registration_course.id}
    parent :registration_courses_registration_settings, registration_course
  end
  crumb :registration_courses_index do
    link I18n.t('registration_courses.course_s'), {:controller=>"registration_courses", :action=>"index"}
    parent :applicants_admins_show
  end
  crumb :registration_courses_new do
    link I18n.t('registration_courses.add_course'), {:controller=>"registration_courses", :action=>"new"}
    parent :registration_courses_index
  end
  crumb :registration_courses_create do
    link I18n.t('registration_courses.add_course'), {:controller=>"registration_courses", :action=>"new"}
    parent :registration_courses_index
  end
  crumb :registration_courses_edit do |registration_course|
    link "#{I18n.t('edit_text')} - #{registration_course.course.course_name}", {:controller=>"registration_courses", :action=>"edit",:id => registration_course.id}
    parent :registration_courses_index
  end
  crumb :applicant_additional_fields_index do
    link I18n.t('applicant_additional_fields.additional_fields'), {:controller=>"applicant_additional_fields", :action=>"index"}
    parent :applicants_admins_show
  end
  crumb :applicant_additional_fields_new do
    link I18n.t('applicant_additional_fields.add_field'), {:controller=>"applicant_additional_fields", :action=>"new"}
    parent :applicant_additional_fields_index
  end
  crumb :applicant_additional_fields_create do
    link I18n.t('applicant_additional_fields.add_field'), {:controller=>"applicant_additional_fields", :action=>"new"}
    parent :applicant_additional_fields_index
  end
  crumb :applicant_additional_fields_show do |addl_field_grp|
    link addl_field_grp.name, {:controller=>"applicant_additional_fields", :action=>"show",:id => addl_field_grp.id, :registration_course_id => addl_field_grp.registration_course_id}
    parent :applicant_additional_fields_index
  end
  crumb :applicant_additional_fields_edit do |addl_field_grp|
    link I18n.t('edit_text'), {:controller=>"applicant_additional_fields", :action=>"edit",:id => addl_field_grp.id, :registration_course_id => addl_field_grp.registration_course_id}
    parent :applicant_additional_fields_show, addl_field_grp
  end
  crumb :pin_groups_index do
    link I18n.t('pin_groups.pin_group_s'), {:controller=>"pin_groups", :action=>"index"}
    parent :applicants_admins_show
  end
  crumb :pin_groups_new do
    link I18n.t('pin_groups.new_pin_group'), {:controller=>"pin_groups", :action=>"new"}
    parent :pin_groups_index
  end
  crumb :pin_groups_create do
    link I18n.t('pin_groups.new_pin_group'), {:controller=>"pin_groups", :action=>"new"}
    parent :pin_groups_index
  end
  crumb :pin_groups_show do |pin_group|
    link pin_group.name_was, {:controller=>"pin_groups", :action=>"show", :id => pin_group.id}
    parent :pin_groups_index
  end
  crumb :pin_groups_edit do |pin_group|
    link I18n.t('edit_text'), {:controller=>"pin_groups", :action=>"show", :id => pin_group.id}
    parent :pin_groups_show,pin_group
  end

  crumb :applicant_additional_fields_view_addl_docs do |student|
    link I18n.t('reg_docs'), {:controller=>"applicant_additional_fields",:action=>"view_addl_docs",:id=>student.id}
    parent :student_profile,student,student.user
  end
end
