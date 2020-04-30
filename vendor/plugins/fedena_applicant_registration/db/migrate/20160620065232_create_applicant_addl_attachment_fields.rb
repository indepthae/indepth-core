class CreateApplicantAddlAttachmentFields < ActiveRecord::Migration
  def self.up
    create_table :applicant_addl_attachment_fields do |t|
      t.string :name
      t.integer :registration_course_id

      t.timestamps
    end
  end

  def self.down
    drop_table :applicant_addl_attachment_fields
  end
end
