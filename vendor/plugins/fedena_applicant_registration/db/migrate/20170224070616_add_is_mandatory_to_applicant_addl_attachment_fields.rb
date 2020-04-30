class AddIsMandatoryToApplicantAddlAttachmentFields < ActiveRecord::Migration
  def self.up
    add_column :applicant_addl_attachment_fields, :is_mandatory, :boolean, :default=>false
  end

  def self.down
    remove_column :applicant_addl_attachment_fields, :is_mandatory
  end
end
