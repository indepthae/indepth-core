class AddFieldsToRegistrationCourses < ActiveRecord::Migration
  def self.up
    add_column :registration_courses, :subject_based_fee_colletion, :boolean
    add_column :registration_courses, :enable_approval_system, :boolean
    add_column :registration_courses, :min_electives, :integer
    add_column :registration_courses, :max_electives, :integer
    add_column :applicants,:subject_ids,:text
  end

  def self.down
    remove_column :registration_courses, :subject_based_fee_collection
    remove_column :registration_courses, :enable_approval_system
    remove_column :registration_courses, :min_electives
    remove_column :registration_courses, :max_electives
    remove_column :applicants, :subject_ids
  end
end
