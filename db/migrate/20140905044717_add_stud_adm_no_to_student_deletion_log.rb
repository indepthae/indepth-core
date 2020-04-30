class AddStudAdmNoToStudentDeletionLog < ActiveRecord::Migration
  def self.up
    add_column :student_deletion_logs, :stud_adm_no, :string
  end

  def self.down
    remove_column :student_deletion_logs, :stud_adm_no
  end
end
