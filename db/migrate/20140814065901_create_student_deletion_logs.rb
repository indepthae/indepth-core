class CreateStudentDeletionLogs < ActiveRecord::Migration
  def self.up
     create_table :student_deletion_logs do |t|
       t.integer :user_id
       t.integer :student_id
       t.varchar :stud_adm_no
       t.text :dependency_messages
       t.integer :school_id
       t.timestamps
       
     end
  end

  def self.down
    drop_table :student_deletion_logs
  end
end
