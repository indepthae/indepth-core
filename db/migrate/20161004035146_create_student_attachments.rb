class CreateStudentAttachments < ActiveRecord::Migration
  def self.up
    create_table :student_attachments do |t|
      t.integer :batch_id
      t.integer :student_id
      t.integer :uploader_id
      t.string :attachment_name

      t.timestamps
    end
  end

  def self.down
    drop_table :student_attachments
  end
end
