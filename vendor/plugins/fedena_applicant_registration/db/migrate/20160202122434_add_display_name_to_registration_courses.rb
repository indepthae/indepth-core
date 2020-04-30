class AddDisplayNameToRegistrationCourses < ActiveRecord::Migration
  def self.up
    add_column :registration_courses, :display_name, :string
  end

  def self.down
    remove_column :registration_courses, :display_name
  end
end
