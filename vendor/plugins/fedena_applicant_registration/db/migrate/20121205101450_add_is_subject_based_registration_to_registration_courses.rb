class AddIsSubjectBasedRegistrationToRegistrationCourses < ActiveRecord::Migration
  def self.up
    add_column :registration_courses, :is_subject_based_registration, :boolean
  end

  def self.down
    remove_column :registration_courses, :is_subject_based_registration
  end
end
