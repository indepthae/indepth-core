class CreateDerivedAssessmentGroupSettings < ActiveRecord::Migration
  def self.up
    create_table :derived_assessment_group_settings do |t|
      t.references :derived_assessment_group
      t.text :value
      t.timestamps
    end
  end

  def self.down
    drop_table :derived_assessment_group_settings
  end
end
