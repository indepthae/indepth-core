class AddAttachmentsAttachmentToReminderAttachment < ActiveRecord::Migration
  def self.up
    add_column :reminder_attachments, :attachment_file_name, :string
    add_column :reminder_attachments, :attachment_content_type, :string
    add_column :reminder_attachments, :attachment_file_size, :integer
    add_column :reminder_attachments, :attachment_updated_at, :datetime
  end

  def self.down
    remove_column :reminder_attachments, :attachment_file_name
    remove_column :reminder_attachments, :attachment_content_type
    remove_column :reminder_attachments, :attachment_file_size
    remove_column :reminder_attachments, :attachment_updated_at
  end
end
