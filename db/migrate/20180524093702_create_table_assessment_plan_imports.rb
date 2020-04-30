class CreateTableAssessmentPlanImports < ActiveRecord::Migration
  def self.up
    create_table :assessment_plan_imports do |t|
      t.integer :import_from
      t.integer :import_to
      t.text :assessment_plan_ids
      t.text :import_settings
      t.integer :status
      t.string :last_error
      
      t.timestamps
    end
  end

  def self.down
    drop_table :assessment_plan_imports
  end
end
