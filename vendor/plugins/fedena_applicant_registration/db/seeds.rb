FinanceTransactionCategory.find_or_create_by_name(:name => 'Applicant Registration', :description => 'Applicant Registration ',\
    :is_income => true)
Privilege.reset_column_information
Privilege.find_or_create_by_name :name => "ApplicantRegistration",:description => "applicant_registration_privilege"
if Privilege.column_names.include?("privilege_tag_id")
  Privilege.find_by_name('ApplicantRegistration').update_attributes(:privilege_tag_id=>PrivilegeTag.find_by_name_tag('student_management').id, :priority=>330 )
end

menu_link_present = MenuLink rescue false
unless menu_link_present == false
  academics_category = MenuLinkCategory.find_by_name("academics")
  MenuLink.create(:name=>'applicant_regi_label',:target_controller=>'applicants_admin',:target_action=>'index',:higher_link_id=>nil,:icon_class=>'applicant-icon',:link_type=>'general',:user_type=>nil,:menu_link_category_id=>academics_category.id) unless MenuLink.exists?(:name=>'applicant_regi_label')
end