class CreateAssessmentActivities < ActiveRecord::Migration
  def self.up
    create_table :assessment_activities do |t|
      t.string :name
      t.string :description
      t.references :assessment_activity_profile
      
      t.timestamps
    end
  end

  def self.down
    drop_table :assessment_activities
  end
end
