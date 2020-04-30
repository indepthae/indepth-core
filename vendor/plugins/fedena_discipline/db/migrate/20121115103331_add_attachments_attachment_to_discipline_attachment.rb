class AddAttachmentsAttachmentToDisciplineAttachment < ActiveRecord::Migration
  def self.up
    add_column :discipline_attachments, :attachment_file_name, :string
    add_column :discipline_attachments, :attachment_content_type, :string
    add_column :discipline_attachments, :attachment_file_size, :integer
    add_column :discipline_attachments, :attachment_updated_at, :datetime
  end

  def self.down
    remove_column :discipline_attachments, :attachment_file_name
    remove_column :discipline_attachments, :attachment_content_type
    remove_column :discipline_attachments, :attachment_file_size
    remove_column :discipline_attachments, :attachment_updated_at
  end
end
