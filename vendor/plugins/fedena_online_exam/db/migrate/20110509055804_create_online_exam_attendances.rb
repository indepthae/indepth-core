class CreateOnlineExamAttendances < ActiveRecord::Migration
  def self.up
    create_table :online_exam_attendances do |t|
        t.references :online_exam_group
        t.references :student
        t.datetime :start_time
        t.datetime :end_time
        t.decimal  :total_score , :precision => 7, :scale=>2
        t.boolean   :is_passed



      t.timestamps
    end
  end

  def self.down
    drop_table :online_exam_attendances
  end
end
