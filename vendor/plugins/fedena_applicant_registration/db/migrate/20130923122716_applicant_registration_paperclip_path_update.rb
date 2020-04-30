class ApplicantRegistrationPaperclipPathUpdate < ActiveRecord::Migration
  def self.up
     Rake::Task["fedena_applicant_registration:update_plugins_paths"].execute
  end

  def self.down
  end
end
