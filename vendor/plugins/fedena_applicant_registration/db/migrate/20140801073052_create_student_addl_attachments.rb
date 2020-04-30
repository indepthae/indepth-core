class CreateStudentAddlAttachments < ActiveRecord::Migration
  def self.up
    create_table :student_addl_attachments do |t|
      t.integer :school_id
      t.references :student
      t.string  :attachment_file_name
      t.string  :attachment_content_type
      t.integer :attachment_file_size
      t.datetime :attachment_updated_at
      t.timestamps
    end
  end

  def self.down
    drop_table :student_addl_attachments
  end
end
