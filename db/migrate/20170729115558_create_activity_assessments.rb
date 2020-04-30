class CreateActivityAssessments < ActiveRecord::Migration
  def self.up
    create_table :activity_assessments do |t|
      t.references :assessment_group_batch
      t.references :assessment_activity_profile
      t.integer :assessment_activity_id
      t.boolean :marks_added, :default => false
      t.integer :submission_status
      t.boolean :edited, :default => false
      
      t.timestamps
    end
  end

  def self.down
    drop_table :activity_assessments
  end
end
