class CreateOverrideAssessmentMarks < ActiveRecord::Migration
  def self.up
    create_table :override_assessment_marks do |t|
      t.references :assessment_group
      t.string :subject_name
      t.string :subject_code
      t.references :course
      t.decimal :maximum_marks, :precision => 10, :scale => 2
      
      t.timestamps
    end
  end

  def self.down
    drop_table :override_assessment_marks
  end
end
