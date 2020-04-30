class AddIsGradebookColumnInBatchWiseStudentReport < ActiveRecord::Migration
  def self.up
    add_column :batch_wise_student_reports, :is_gradebook, :boolean, :default => false
    add_index :batch_wise_student_reports, :is_gradebook
  end

  def self.down
    remove_column :batch_wise_student_reports, :is_gradebook
    remove_index :batch_wise_student_reports, :is_gradebook
  end
end
