class CreateAssessmentAttributes < ActiveRecord::Migration
  def self.up
    create_table :assessment_attributes do |t|
      t.string :name
      t.string :description
      t.references :assessment_attribute_profile
      t.decimal :maximum_marks,:precision => 10, :scale => 2
      t.timestamps
    end
  end

  def self.down
    drop_table :assessment_attributes
  end
end
