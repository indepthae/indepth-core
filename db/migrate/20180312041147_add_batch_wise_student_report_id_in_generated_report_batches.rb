class AddBatchWiseStudentReportIdInGeneratedReportBatches < ActiveRecord::Migration
  def self.up
    add_column :generated_report_batches, :batch_wise_student_report_id, :integer
    add_index  :generated_report_batches, :batch_wise_student_report_id, :name => "index_on_report"
  end

  def self.down
   remove_column :generated_report_batches, :batch_wise_student_report_id
   remove_index  :generated_report_batches, :batch_wise_student_report_id, :name => "index_on_report"
  end
end
