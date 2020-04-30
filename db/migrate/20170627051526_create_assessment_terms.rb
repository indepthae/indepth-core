class CreateAssessmentTerms < ActiveRecord::Migration
  def self.up
    create_table :assessment_terms do |t|
      t.string :name
      t.date :start_date
      t.date :end_date
      t.references :assessment_plan
      
      t.timestamps
    end
  end

  def self.down
    drop_table :assessment_terms
  end
end
