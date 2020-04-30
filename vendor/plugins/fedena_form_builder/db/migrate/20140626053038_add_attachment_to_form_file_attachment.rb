class AddAttachmentToFormFileAttachment < ActiveRecord::Migration
  def self.up
    add_column :form_file_attachments, :attachment_file_name, :string
    add_column :form_file_attachments, :attachment_content_type, :string
    add_column :form_file_attachments, :attachment_file_size, :integer
    add_column :form_file_attachments, :attachment_updated_at, :datetime
  end

  def self.down
    remove_column :form_file_attachments, :attachment_file_name, :string
    remove_column :form_file_attachments, :attachment_content_type, :string
    remove_column :form_file_attachments, :attachment_file_size, :integer
    remove_column :form_file_attachments, :attachment_updated_at, :datetime
  end
end
