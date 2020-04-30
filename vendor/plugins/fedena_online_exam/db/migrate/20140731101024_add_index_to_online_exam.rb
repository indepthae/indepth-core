class AddIndexToOnlineExam < ActiveRecord::Migration
  def self.up
    add_index :online_exam_attendances, [:online_exam_group_id,:student_id], :name=>'by_exam_and_student'
    add_index :online_exam_questions, [:question_format,:subject_id], :name=>'by_format_and_subject'
    add_index :online_exam_score_details, [:online_exam_attendance_id]
    add_index :online_exam_groups_batches, [:online_exam_group_id]
    add_index :online_exam_groups_batches, [:batch_id]
    add_index :online_exam_groups_students, [:online_exam_group_id]
    add_index :online_exam_groups_students, [:student_id]
    add_index :online_exam_groups_employees, [:online_exam_group_id]
    add_index :online_exam_groups_employees, [:employee_id]
    add_index :online_exam_groups_subjects, [:online_exam_group_id]
  end

  def self.down
    remove_index :online_exam_attendances, [:online_exam_group_id,:student_id], :name=>'by_exam_and_student'
    remove_index :online_exam_questions, [:question_format,:subject_id], :name=>'by_format_and_subject'
    remove_index :online_exam_score_details, [:online_exam_attendance_id]
    remove_index :online_exam_groups_batches, [:online_exam_group_id]
    remove_index :online_exam_groups_batches, [:batch_id]
    remove_index :online_exam_groups_students, [:online_exam_group_id]
    remove_index :online_exam_groups_students, [:student_id]
    remove_index :online_exam_groups_employees, [:online_exam_group_id]
    remove_index :online_exam_groups_employees, [:employee_id]
    remove_index :online_exam_groups_subjects, [:online_exam_group_id]
  end
end
