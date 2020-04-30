class AddingIndicesForStudentRecords < ActiveRecord::Migration
  def self.up
    add_index :record_assignments,:record_group_id
    add_index :record_assignments,:course_id
    add_index :record_batch_assignments, :record_assignment_id
    add_index :record_batch_assignments, :record_group_id
    add_index :record_batch_assignments, :batch_id
    add_index :records, :record_group_id
    add_index :student_records, :additional_field_id
    add_index :student_records, :student_id
    add_index :student_records, :batch_id
  end

  def self.down
    remove_index :record_assignments,:record_group_id
    remove_index :record_assignments,:course_id
    remove_index :record_batch_assignments, :record_assignment_id
    remove_index :record_batch_assignments, :record_group_id
    remove_index :record_batch_assignments, :batch_id
    remove_index :records, :record_group_id
    remove_index :student_records, :additional_field_id
    remove_index :student_records, :student_id
    remove_index :student_records, :batch_id
  end
end
