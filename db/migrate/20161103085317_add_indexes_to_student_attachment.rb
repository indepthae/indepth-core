class AddIndexesToStudentAttachment < ActiveRecord::Migration
  def self.up
    add_index :student_attachments, :student_id, :name => "index_on_student_id"
    add_index :student_attachments, [:student_id, :is_registered], :name => "index_on_student_id_and_is_registered"
    add_index :student_attachment_records, :student_attachment_id, :name => "index_on_student_attachment_id"
    add_index :student_attachment_records, :student_attachment_category_id, :name => "index_on_student_attachment_category_id"
  end

  def self.down
    remove_index :student_attachments, :student_id, :name => "index_on_student_id"
    remove_index :student_attachments, [:student_id, :is_registered], :name => "index_on_student_id_and_is_registered"
    remove_index :student_attachment_records, :student_attachment_id, :name => "index_on_student_attachment_id"
    remove_index :student_attachment_records, :student_attachment_category_id, :name => "index_on_student_attachment_category_id"
  end
end
