class AddIndexToStudentAddlAttachment < ActiveRecord::Migration
  def self.up
    add_index :student_addl_attachments, :student_id
  end

  def self.down
    remove_index :student_addl_attachments, :student_id
  end
end
