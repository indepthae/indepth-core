class CreateAssessmentPlans < ActiveRecord::Migration
  def self.up
    create_table :assessment_plans do |t|
      t.string :name
      t.integer :terms_count
      t.references :academic_year
      
      t.timestamps
    end
  end

  def self.down
    drop_table :assessment_plans
  end
end
