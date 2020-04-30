class CreateAssessmentAttributeProfiles < ActiveRecord::Migration
  def self.up
    create_table :assessment_attribute_profiles do |t|
      t.string  :name
      t.string  :display_name
      t.string  :description
      t.string  :formula
      t.decimal :maximum_marks,:precision => 10, :scale => 2
      t.decimal :maximum_subject_marks,:precision => 10, :scale => 2
      
      t.timestamps
    end
  end

  def self.down
    drop_table :assessment_attribute_profiles
  end
end
