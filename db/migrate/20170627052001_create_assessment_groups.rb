class CreateAssessmentGroups < ActiveRecord::Migration
  def self.up
    create_table :assessment_groups do |t|
      t.string :name
      t.string :code
      t.string :display_name
      t.string :type
      t.integer :parent_id
      t.string :parent_type
      t.references :assessment_plan
      t.references :assessment_activity_profile
      t.integer :scoring_type
      t.references :grade_set
      t.boolean :is_single_mark_entry, :default => true
      t.boolean :is_attribute_same, :default => true
      t.references :assessment_attribute_profile
      t.decimal :maximum_marks, :precision => 10, :scale => 2
      t.decimal :minimum_marks, :precision => 10, :scale => 2
      t.references :academic_year
      
      t.timestamps
    end
  end

  def self.down
    drop_table :assessment_groups
  end
end
