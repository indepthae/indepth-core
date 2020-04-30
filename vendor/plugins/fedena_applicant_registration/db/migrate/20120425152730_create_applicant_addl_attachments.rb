class CreateApplicantAddlAttachments < ActiveRecord::Migration
  def self.up
    create_table :applicant_addl_attachments do |t|
      t.integer :school_id
      t.references :applicant
      t.string  :attachment_file_name
      t.string  :attachment_content_type
      t.integer :attachment_file_size
      t.timestamps
    end
  end

  def self.down
    drop_table :applicant_addl_attachments
  end
end