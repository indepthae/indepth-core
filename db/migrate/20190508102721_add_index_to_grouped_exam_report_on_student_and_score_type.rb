class AddIndexToGroupedExamReportOnStudentAndScoreType < ActiveRecord::Migration
  def self.up
     add_index :grouped_exam_reports, [:student_id, :score_type] , :name => 'index_on_student_id_and_score_type'
  end

  def self.down
    remove_index :grouped_exam_reports,  :name => "index_on_student_id_and_score_type"
  end
end
