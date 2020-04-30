require 'translator'
require File.join(File.dirname(__FILE__), "lib", "fedena_applicant_registration")
require File.join(File.dirname(__FILE__), "config", "breadcrumbs")

FedenaPlugin.register = {
  :name=>"fedena_applicant_registration",
  :description=>"Fedena Applicant Registration",
  :auth_file=>"config/applicant_regi_auth.rb",
  :more_menu=>{:title=>"applicant_regi_label",:controller=>"applicants_admin",:action=>"index",:target_id=>"more-parent"},
  :multischool_models=>%w{ApplicantAddlAttachment ApplicantAddlFieldGroup ApplicantAddlField ApplicantAddlFieldValue ApplicantAddlValue ApplicantGuardian ApplicantPreviousData Applicant ApplicantRegistrationSetting RegistrationCourse PinGroup PinNumber CoursePin ApplicantAdditionalDetail ApplicationStatus ApplicationInstruction ApplicantStudentAddlField ApplicationSection ApplicantAddlAttachmentField StudentAddlAttachment},
  :multischool_classes=>%w{FedenaApplicantRegistration::ApplicantMail FedenaApplicantRegistration::ApplicantMessageMail},
  :finance=>{:category_name=>"Applicant Registration",:destination=>{:controller=>"finance" , :action => "income_details"},:plugin_name=>"fedena_applicant_registration"},
#  :student_profile_more_menu=>{:title=>"reg_docs",:destination=>{:controller=>"applicant_additional_fields",:action=>"view_addl_docs"}}
}

FedenaApplicantRegistration.attach_overrides

Dir[File.join("#{File.dirname(__FILE__)}/config/locales/*.yml")].each do |locale|
  I18n.load_path.unshift(locale)
end



