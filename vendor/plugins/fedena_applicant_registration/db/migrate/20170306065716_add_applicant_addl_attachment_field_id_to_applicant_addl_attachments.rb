class AddApplicantAddlAttachmentFieldIdToApplicantAddlAttachments < ActiveRecord::Migration
  def self.up
    add_column :applicant_addl_attachments, :applicant_addl_attachment_field_id, :integer
  end

  def self.down
    remove_column :applicant_addl_attachments, :applicant_addl_attachment_field_id
  end
end
