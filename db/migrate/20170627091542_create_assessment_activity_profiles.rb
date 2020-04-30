class CreateAssessmentActivityProfiles < ActiveRecord::Migration
  def self.up
    create_table :assessment_activity_profiles do |t|
      t.string :name
      t.string :display_name
      t.string :description
      
      t.timestamps
    end
  end

  def self.down
    drop_table :assessment_activity_profiles
  end
end
