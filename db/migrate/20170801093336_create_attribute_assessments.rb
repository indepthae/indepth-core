class CreateAttributeAssessments < ActiveRecord::Migration
  def self.up
    create_table :attribute_assessments do |t|
      t.references :assessment_group_batch
      t.references :subject
      t.references :assessment_attribute_profile
      t.integer :assessment_attribute_id
      t.boolean :marks_added, :default => false
      t.integer :submission_status
      t.boolean :edited, :default => false
      
      t.timestamps
    end
  end

  def self.down
    drop_table :attribute_assessments
  end
end