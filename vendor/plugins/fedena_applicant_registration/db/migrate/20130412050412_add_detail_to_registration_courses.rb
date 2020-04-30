class AddDetailToRegistrationCourses < ActiveRecord::Migration
  def self.up
    add_column :registration_courses, :include_additional_details, :boolean
    add_column :registration_courses, :additional_field_ids, :string
  end

  def self.down
    remove_column :registration_courses, :include_additional_details
    remove_column :registration_courses, :additional_field_ids
  end
end
