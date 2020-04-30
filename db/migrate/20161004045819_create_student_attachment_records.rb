class CreateStudentAttachmentRecords < ActiveRecord::Migration
  def self.up
    create_table :student_attachment_records do |t|
      t.integer :student_attachment_id
      t.integer :student_attachment_category_id
      t.integer :record_manager_id

      t.timestamps
    end
  end

  def self.down
    drop_table :student_attachment_records
  end
end
