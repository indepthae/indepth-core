class CreateTableSkillAssessments < ActiveRecord::Migration
  def self.up
    create_table :skill_assessments do |t|
      t.references :subject
      t.references :subject_skill
      t.references :subject_assessment
      t.boolean :marks_added, :default => false
      t.integer :submission_status
      t.boolean :edited, :default => false
      t.integer :higher_assessment_id
      
      t.timestamps
    end
  end

  def self.down
    drop_table :skill_assessments 
  end
end
