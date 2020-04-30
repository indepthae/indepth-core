class CreateBatchWiseStudentReport < ActiveRecord::Migration
  def self.up
    create_table :batch_wise_student_reports do |t|
      t.string :status
      t.text :parameters
      t.string  :report_file_name
      t.string  :report_content_type
      t.integer :report_file_size
      t.datetime :report_updated_at
      t.references :course
      t.integer :school_id
      t.timestamps
    end
  end

  def self.down
    drop_table :batch_wise_student_reports
  end
end
