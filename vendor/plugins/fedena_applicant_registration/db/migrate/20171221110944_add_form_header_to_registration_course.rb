class AddFormHeaderToRegistrationCourse < ActiveRecord::Migration
  def self.up
    add_column :registration_courses, :form_header, :string
  end

  def self.down
    remove_column :registration_courses, :form_header
  end
end
