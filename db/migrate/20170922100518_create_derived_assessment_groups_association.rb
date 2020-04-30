class CreateDerivedAssessmentGroupsAssociation < ActiveRecord::Migration
  def self.up
    create_table :derived_assessment_groups_associations do |t|
      t.references :derived_assessment_group
      t.integer :assessment_group_id
      t.decimal :weightage
      t.timestamps
    end
  end

  def self.down
    drop_table :derived_assessment_groups_associations
  end
end
