class CreateConvertedAssessmentMarks < ActiveRecord::Migration
  def self.up
    create_table :converted_assessment_marks do |t|
      t.integer :markable_id
      t.string :markable_type
      t.references :assessment_group_batch
      t.references :assessment_group
      t.references :student
      t.decimal :mark, :precision => 10, :scale => 2
      t.string :grade
      t.decimal :credit_points, :precision => 10, :scale => 2
      t.boolean :passed, :default => true
      t.string :description
      t.boolean :is_absent, :default => false
      t.text :actual_mark
      
      t.timestamps
    end
  end

  def self.down
    drop_table :converted_assessment_marks
  end
end
