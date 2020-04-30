class CreateAssessmentMarks < ActiveRecord::Migration
  def self.up
    create_table :assessment_marks do |t|
      t.references :student
      t.string  :assessment_type
      t.integer :assessment_id
      t.decimal :marks, :precision => 10, :scale => 2
      t.string :grade
      t.integer :grade_id
      t.boolean :is_absent, :default => false
      t.timestamps
    end
  end

  def self.down
    drop_table :assessment_marks
  end
end
