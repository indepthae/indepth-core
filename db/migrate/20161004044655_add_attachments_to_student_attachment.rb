class AddAttachmentsToStudentAttachment < ActiveRecord::Migration
  def self.up
    add_column :student_attachments, :attachment_file_name, :string
    add_column :student_attachments, :attachment_content_type, :string
    add_column :student_attachments, :attachment_file_size, :integer
    add_column :student_attachments, :attachment_updated_at, :datetime
  end

  def self.down
    remove_column :student_attachments, :attachment_file_name
    remove_column :student_attachments, :attachment_content_type
    remove_column :student_attachments, :attachment_file_size
    remove_column :student_attachments, :attachment_updated_at
  end
end
