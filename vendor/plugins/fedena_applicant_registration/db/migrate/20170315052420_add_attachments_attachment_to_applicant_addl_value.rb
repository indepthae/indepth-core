class AddAttachmentsAttachmentToApplicantAddlValue < ActiveRecord::Migration
  def self.up
    add_column :applicant_addl_values, :attachment_file_name, :string
    add_column :applicant_addl_values, :attachment_content_type, :string
    add_column :applicant_addl_values, :attachment_file_size, :integer
    add_column :applicant_addl_values, :attachment_updated_at, :datetime
    add_column :applicant_addl_values, :applicant_guardian_id, :integer
  end

  def self.down
    remove_column :applicant_addl_values, :attachment_file_name
    remove_column :applicant_addl_values, :attachment_content_type
    remove_column :applicant_addl_values, :attachment_file_size
    remove_column :applicant_addl_values, :attachment_updated_at
    remove_column :applicant_addl_values, :applicant_guardian_id
  end
end
