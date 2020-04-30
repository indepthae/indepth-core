class AddIndexStudentIdStudentBatchTable < ActiveRecord::Migration
  def self.up
    add_index :batch_students, :student_id
  end

  def self.down
    remove_index :batch_students, :student_id
  end
end
