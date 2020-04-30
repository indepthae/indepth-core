class CreateSubjectAssessments < ActiveRecord::Migration
  def self.up
    create_table :subject_assessments do |t|
      t.references :assessment_group_batch
      t.date :exam_date
      t.time :start_time
      t.time :end_time
      t.references :subject
      t.references :elective_group
      t.decimal :maximum_marks, :precision => 10, :scale => 2
      t.decimal :minimum_marks, :precision => 10, :scale => 2
      t.boolean :marks_added, :default => false
      t.integer :submission_status
      t.boolean :edited, :default => false
      
      t.timestamps
    end
  end

  def self.down
    drop_table :subject_assessments
  end
end
