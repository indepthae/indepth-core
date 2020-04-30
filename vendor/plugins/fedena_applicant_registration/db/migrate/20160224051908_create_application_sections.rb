class CreateApplicationSections < ActiveRecord::Migration
  def self.up
    create_table :application_sections do |t|
      t.integer :registration_course_id
      t.string :section_name
      t.integer :custom_section_id
      t.text :section_fields
      t.integer :guardian_count

      t.timestamps
    end
  end

  def self.down
    drop_table :application_sections
  end
end
