class CreateSubjectAttributeAssessments < ActiveRecord::Migration
  def self.up
    create_table :subject_attribute_assessments do |t|
      t.references :assessment_group_batch
      t.references :subject
      t.references :batch
      t.references :assessment_attribute_profile
      t.integer :submission_status
      t.boolean :marks_added, :default =>  false
  
      t.timestamps
    end
    add_column :attribute_assessments, :subject_attribute_assessment_id, :integer
  end

  def self.down
    drop_table :subject_attribute_assessments
    remove_column :attribute_assessments, :subject_attribute_assessment_id
  end
end
